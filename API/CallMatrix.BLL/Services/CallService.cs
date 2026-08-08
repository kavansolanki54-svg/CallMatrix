using AutoMapper;
using CallMatrix.BLL.Interfaces;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Calls;
using CallMatrix.DTO.Response.Calls;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.BLL.Services
{
    public class CallService : ICallService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;
        private static readonly System.Collections.Concurrent.ConcurrentDictionary<int, System.Threading.SemaphoreSlim> _uploadLocks = 
            new System.Collections.Concurrent.ConcurrentDictionary<int, System.Threading.SemaphoreSlim>();

        public CallService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<PaginatedResponse<CallLogResponse>>> GetCallsAsync(PaginationRequest request, int companyId, int? employeeId = null)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;
            if (employeeId.HasValue)
            {
                filters["EmployeeId"] = employeeId.Value;
            }
            if (request.Date.HasValue)
            {
                filters["Date"] = request.Date.Value;
            }

            var (items, totalCount) = await _unitOfWork.Calls.GetPagedAsync(
                request.Page,
                request.PageSize,
                request.Search,
                request.SortBy ?? "CallDateTime",
                request.SortOrder ?? "DESC",
                filters);

            var dtos = _mapper.Map<IEnumerable<CallLogResponse>>(items);
            var result = new PaginatedResponse<CallLogResponse>(dtos, totalCount, request.Page, request.PageSize);

            return ApiResponse<PaginatedResponse<CallLogResponse>>.Ok(result, "Call logs retrieved successfully");
        }

        public async Task<ApiResponse<CallLogResponse>> CreateCallLogAsync(CreateCallLogRequest request, int employeeId)
        {
            var entity = _mapper.Map<CallMaster>(request);
            entity.EmployeeId = employeeId;
            entity.SyncedAt = DateTime.Now;
            entity.CreatedAt = DateTime.Now;
            entity.CreatedBy = employeeId;
            entity.IsActive = true;

            await _unitOfWork.Calls.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var dto = _mapper.Map<CallLogResponse>(entity);
            return ApiResponse<CallLogResponse>.Ok(dto, "Call log created successfully", 201);
        }

        public async Task<ApiResponse<bool>> SyncCallsAsync(SyncCallsRequest request, int employeeId)
        {
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                int addedCount = 0;
                foreach (var callDto in request.Calls)
                {
                    // Check if identical call log already exists in the database
                    var exists = await _unitOfWork.Calls.Query().AnyAsync(c =>
                        c.EmployeeId == employeeId &&
                        c.PhoneNumber == callDto.PhoneNumber &&
                        c.CallType == callDto.CallType &&
                        c.Duration == callDto.Duration &&
                        c.CallDateTime == callDto.CallDateTime
                    );

                    if (exists)
                    {
                        continue; // Skip duplicates
                    }

                    var entity = _mapper.Map<CallMaster>(callDto);
                    entity.CompanyId = request.CompanyId;
                    entity.DeviceId = request.DeviceId;
                    entity.EmployeeId = employeeId;
                    entity.SyncedAt = DateTime.Now;
                    entity.CreatedAt = DateTime.Now;
                    entity.CreatedBy = employeeId;
                    entity.IsActive = true;

                    await _unitOfWork.Calls.AddAsync(entity);
                    addedCount++;
                }

                if (addedCount > 0)
                {
                    await _unitOfWork.SaveChangesAsync();
                }
                await _unitOfWork.CommitTransactionAsync();

                return ApiResponse<bool>.Ok(true, $"{addedCount} call logs synchronized successfully");
            }
            catch
            {
                await _unitOfWork.RollbackTransactionAsync();
                throw;
            }
        }

        public async Task<ApiResponse<CallRecordingResponse>> SaveCallRecordingAsync(UploadCallRecordingRequest request, System.IO.Stream? fileStream, string? fileExtension, int employeeId)
        {
            var myLock = _uploadLocks.GetOrAdd(request.CallId, _ => new System.Threading.SemaphoreSlim(1, 1));
            await myLock.WaitAsync();
            try
            {
                System.Console.WriteLine($"[CallService] SaveCallRecordingAsync starting: CallId={request.CallId}, employeeId={employeeId}, fileName={request.FileName}, duration={request.Duration}, fileSize={request.FileSize}");

                var call = await _unitOfWork.Calls.GetByIdAsync(request.CallId);
                if (call == null || !call.IsActive)
                {
                    System.Console.Error.WriteLine($"[CallService] SaveCallRecordingAsync error: Call record not found or inactive for CallId={request.CallId}");
                    return ApiResponse<CallRecordingResponse>.Fail("Call record not found", 404);
                }

                // Check if a recording already exists for this CallId
                var existingRecording = await _unitOfWork.CallRecordings.Query()
                    .FirstOrDefaultAsync(r => r.CallId == request.CallId && r.IsActive);

                string? fileUrl = request.FileUrl;
                string? filePath = request.FilePath;

                if (fileStream != null && fileStream.Length > 0)
                {
                    try
                    {
                        // Extract date components
                        var targetDate = request.RecordingDate ?? call.CallDateTime;
                        var year = targetDate.ToString("yyyy");
                        var month = targetDate.ToString("MM");
                        var day = targetDate.ToString("dd");

                        // Clean phone number for safety in folder/file naming
                        var cleanPhone = string.IsNullOrEmpty(call.PhoneNumber) ? "Unknown" : call.PhoneNumber.Replace("+", "").Replace(" ", "").Replace("-", "");

                        // Build relative directory structure: recordings/Company_X/Employee_Y/Year/Month/Day
                        var relativeDir = System.IO.Path.Combine("recordings", $"Company_{call.CompanyId}", $"Employee_{employeeId}", year, month, day);
                        
                        var baseDir = AppDomain.CurrentDomain.BaseDirectory;
                        string uploadsFolder;
                        if (baseDir.Contains("bin") && (baseDir.Contains("Debug") || baseDir.Contains("Release")))
                        {
                            var projectRoot = System.IO.Directory.GetParent(baseDir)?.Parent?.Parent?.FullName ?? baseDir;
                            uploadsFolder = System.IO.Path.Combine(projectRoot, "wwwroot", relativeDir);
                        }
                        else
                        {
                            uploadsFolder = System.IO.Path.Combine(baseDir, relativeDir);
                        }

                        if (!System.IO.Directory.Exists(uploadsFolder))
                        {
                            System.Console.WriteLine($"[CallService] SaveCallRecordingAsync creating folder: {uploadsFolder}");
                            System.IO.Directory.CreateDirectory(uploadsFolder);
                        }

                        var extension = string.IsNullOrEmpty(fileExtension) ? ".mp3" : fileExtension;
                        if (!extension.StartsWith('.')) extension = "." + extension;

                        var fileName = $"{cleanPhone}_{call.CallId}{extension}";
                        filePath = System.IO.Path.Combine(uploadsFolder, fileName);

                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync saving file to: {filePath}");
                        using (var targetStream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                        {
                            await fileStream.CopyToAsync(targetStream);
                        }

                        // Construct static file URL
                        var relativeFileUrl = System.IO.Path.Combine(relativeDir, fileName).Replace("\\", "/");
                        fileUrl = $"/{relativeFileUrl}";
                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync saved file successfully: URL={fileUrl}");
                    }
                    catch (System.Exception ex)
                    {
                        System.Console.Error.WriteLine($"[CallService] SaveCallRecordingAsync filesystem exception for CallId={request.CallId}: {ex.Message}\n{ex.StackTrace}");
                        throw;
                    }
                }
                else
                {
                    System.Console.Error.WriteLine($"[CallService] SaveCallRecordingAsync warning: fileStream is null or empty for CallId={request.CallId}");
                }

                try
                {
                    if (existingRecording != null)
                    {
                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync: updating existing recording entry with ID={existingRecording.CallRecordingId} for CallId={request.CallId}");
                        // Update existing recording entry
                        existingRecording.FileName = request.FileName;
                        existingRecording.Duration = request.Duration;
                        existingRecording.FileSize = request.FileSize;
                        existingRecording.UploadStatus = "Completed";
                        existingRecording.UpdatedAt = DateTime.Now;
                        existingRecording.UpdatedBy = employeeId;
                        if (!string.IsNullOrEmpty(filePath)) existingRecording.FilePath = filePath;
                        if (!string.IsNullOrEmpty(fileUrl)) existingRecording.FileUrl = fileUrl;
                        if (request.RecordingDate.HasValue) existingRecording.RecordingDate = request.RecordingDate.Value;

                        await _unitOfWork.CallRecordings.UpdateAsync(existingRecording);
                        await _unitOfWork.SaveChangesAsync();

                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync database update succeeded for CallId={request.CallId}");
                        var updateDto = _mapper.Map<CallRecordingResponse>(existingRecording);
                        return ApiResponse<CallRecordingResponse>.Ok(updateDto, "Call recording updated successfully", 200);
                    }
                    else
                    {
                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync: adding new recording entry for CallId={request.CallId}");
                        // Add new recording entry
                        var entity = _mapper.Map<CallRecording>(request);
                        entity.CompanyId = call.CompanyId;
                        entity.UploadStatus = "Completed";
                        entity.CreatedAt = DateTime.Now;
                        entity.CreatedBy = employeeId;
                        entity.IsActive = true;
                        entity.FilePath = filePath;
                        entity.FileUrl = fileUrl;

                        await _unitOfWork.CallRecordings.AddAsync(entity);
                        await _unitOfWork.SaveChangesAsync();

                        System.Console.WriteLine($"[CallService] SaveCallRecordingAsync database insert succeeded for CallId={request.CallId}");
                        var dto = _mapper.Map<CallRecordingResponse>(entity);
                        return ApiResponse<CallRecordingResponse>.Ok(dto, "Call recording saved successfully", 201);
                    }
                }
                catch (System.Exception ex)
                {
                    System.Console.Error.WriteLine($"[CallService] SaveCallRecordingAsync database transaction exception for CallId={request.CallId}: {ex.Message}\n{ex.StackTrace}");
                    throw;
                }
            }
            finally
            {
                myLock.Release();
            }
        }

        public async Task<ApiResponse<CallAnalyticsSummaryResponse>> GetAnalyticsSummaryAsync(int companyId, DateTime? startDate, DateTime? endDate, int? employeeId = null)
        {
            var calls = await _unitOfWork.Calls.GetCallsByCompanyIdAsync(companyId);

            if (startDate.HasValue)
                calls = calls.Where(c => c.CallDateTime >= startDate.Value);

            if (endDate.HasValue)
                calls = calls.Where(c => c.CallDateTime <= endDate.Value);

            if (employeeId.HasValue)
                calls = calls.Where(c => c.EmployeeId == employeeId.Value);

            var callList = calls.ToList();
            int totalCount = callList.Count;

            int incoming = callList.Count(c => c.CallType.Equals("Incoming", StringComparison.OrdinalIgnoreCase));
            int outgoing = callList.Count(c => c.CallType.Equals("Outgoing", StringComparison.OrdinalIgnoreCase));
            int missed = callList.Count(c => c.CallType.Equals("Missed", StringComparison.OrdinalIgnoreCase));

            long totalDuration = callList.Sum(c => (long)(c.Duration ?? 0));
            double avgDuration = totalCount > 0 ? (double)totalDuration / totalCount : 0;

            var recordings = await _unitOfWork.CallRecordings.GetRecordingsByCompanyIdAsync(companyId);
            if (employeeId.HasValue)
            {
                var callIds = callList.Select(c => c.CallId).ToHashSet();
                recordings = recordings.Where(r => callIds.Contains(r.CallId));
            }

            var summary = new CallAnalyticsSummaryResponse
            {
                TotalCalls = totalCount,
                TotalIncomingCalls = incoming,
                TotalOutgoingCalls = outgoing,
                TotalMissedCalls = missed,
                TotalDurationSeconds = totalDuration,
                AverageDurationSeconds = Math.Round(avgDuration, 2),
                TotalRecordings = recordings.Count()
            };

            return ApiResponse<CallAnalyticsSummaryResponse>.Ok(summary, "Call analytics summary generated successfully");
        }

        public async Task<ApiResponse<DashboardSummaryResponse>> GetDashboardSummaryAsync(int companyId, DateTime? date = null, int? employeeId = null)
        {
            // 1. Get calls for the company
            var calls = await _unitOfWork.Calls.GetCallsByCompanyIdAsync(companyId);
            var callList = calls.ToList();

            // 2. Get leads for the company
            var leads = await _unitOfWork.Leads.GetAllAsync();
            var leadList = leads.Where(l => l.CompanyId == companyId).ToList();

            // 3. Get active devices count
            var devices = await _unitOfWork.Devices.GetAllAsync();
            var deviceList = devices.Where(d => d.CompanyId == companyId && d.IsActive).ToList();

            // Apply Employee Filter if provided
            if (employeeId.HasValue)
            {
                callList = callList.Where(c => c.EmployeeId == employeeId.Value).ToList();
                leadList = leadList.Where(l => l.AssignedTo == employeeId.Value || l.CreatedBy == employeeId.Value).ToList();
                deviceList = deviceList.Where(d => d.EmployeeId == employeeId.Value).ToList();
            }

            int totalDevices = deviceList.Count;

            // Keep copies of lists for weekly chart generation
            var chartCallList = callList;
            var chartLeadList = leadList;

            // Apply Date Filter if provided
            if (date.HasValue)
            {
                var targetDate = date.Value.Date;
                callList = callList.Where(c => c.CallDateTime.Date == targetDate).ToList();
                leadList = leadList.Where(l => l.CreatedAt.Date == targetDate).ToList();
            }

            int totalCalls = callList.Count;
            int totalLeads = leadList.Count;

            // 4. Calculate average duration
            long totalDuration = callList.Sum(c => (long)(c.Duration ?? 0));
            double avgDuration = totalCalls > 0 ? (double)totalDuration / totalCalls : 0;

            // 5. Outcomes
            int incoming = callList.Count(c => c.CallType.Equals("Incoming", StringComparison.OrdinalIgnoreCase));
            int outgoing = callList.Count(c => c.CallType.Equals("Outgoing", StringComparison.OrdinalIgnoreCase));
            int missed = callList.Count(c => c.CallType.Equals("Missed", StringComparison.OrdinalIgnoreCase));
            int answered = incoming + outgoing;

            // 6. Weekly series (last 7 days ending on the filtered date or latest call date)
            var endDate = date ?? (chartCallList.Any() ? chartCallList.Max(c => c.CallDateTime).Date : DateTime.Today);
            var last7Days = Enumerable.Range(0, 7)
                .Select(i => endDate.AddDays(-6 + i))
                .ToList();

            var weeklyCallVolume = last7Days
                .Select(d => chartCallList.Count(c => c.CallDateTime.Date == d.Date))
                .ToList();

            var weeklyLeadConversions = last7Days
                .Select(d => chartLeadList.Count(l => l.CreatedAt.Date == d.Date))
                .ToList();

            var weeklyLabels = last7Days.Select(d => d.ToString("ddd")).ToList();

            var summary = new DashboardSummaryResponse
            {
                TotalCalls = totalCalls,
                TotalLeads = totalLeads,
                TotalDevices = totalDevices,
                AverageDurationSeconds = Math.Round(avgDuration, 2),
                
                AnsweredCalls = answered,
                MissedCalls = missed,
                RejectedCalls = 0,
                BusyCalls = 0,

                WeeklyCallVolume = weeklyCallVolume,
                WeeklyLeadConversions = weeklyLeadConversions,
                WeeklyLabels = weeklyLabels
            };

            return ApiResponse<DashboardSummaryResponse>.Ok(summary, "Dashboard summary calculated successfully");
        }

        public async Task<ApiResponse<PaginatedResponse<CallRecordingResponse>>> GetRecordingsAsync(PaginationRequest request, int companyId, int? employeeId = null)
        {
            var query = _unitOfWork.CallRecordings.Query()
                .Include(r => r.Call)
                .ThenInclude(c => c.Employee)
                .AsNoTracking()
                .Where(r => r.CompanyId == companyId && r.IsActive);

            // Deduplicate: Only get the latest CallRecording record per CallId
            query = query.Where(r => r.CallRecordingId == _unitOfWork.CallRecordings.Query()
                .Where(sub => sub.CallId == r.CallId && sub.IsActive)
                .OrderByDescending(sub => sub.CreatedAt)
                .Select(sub => sub.CallRecordingId)
                .FirstOrDefault());

            if (employeeId.HasValue)
            {
                query = query.Where(r => r.CreatedBy == employeeId.Value);
            }

            if (request.Date.HasValue)
            {
                var targetDate = request.Date.Value.Date;
                query = query.Where(r => r.RecordingDate.HasValue ? r.RecordingDate.Value.Date == targetDate : r.CreatedAt.Date == targetDate);
            }

            if (!string.IsNullOrEmpty(request.Search))
            {
                query = query.Where(r => r.Call.PhoneNumber.Contains(request.Search) || (r.Call.ContactName != null && r.Call.ContactName.Contains(request.Search)));
            }

            query = query.OrderByDescending(r => r.CreatedAt);

            int totalCount = await query.CountAsync();
            var items = await query
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToListAsync();

            var dtos = items.Select(r => new CallRecordingResponse
            {
                CallRecordingId = r.CallRecordingId,
                CompanyId = r.CompanyId,
                CallId = r.CallId,
                FileName = r.FileName,
                FilePath = r.FilePath,
                FileUrl = r.FileUrl,
                Duration = r.Duration ?? 0,
                PhoneNumber = r.Call?.PhoneNumber ?? "Unknown",
                ContactName = r.Call?.ContactName,
                EmployeeName = r.Call?.Employee?.EmployeeName ?? $"Employee #{r.CreatedBy}",
                EmployeeId = r.Call?.EmployeeId ?? r.CreatedBy ?? 0,
                CallDateTime = r.Call?.CallDateTime ?? r.CreatedAt,
                CallType = r.Call?.CallType ?? "Incoming",
                FileSize = r.FileSize ?? 0,
                UploadStatus = r.UploadStatus,
                RecordingDate = r.RecordingDate,
                CreatedAt = r.CreatedAt,
                AiSummary = r.AiSummary
            }).ToList();

            var paginated = new PaginatedResponse<CallRecordingResponse>(dtos, totalCount, request.Page, request.PageSize);
            return ApiResponse<PaginatedResponse<CallRecordingResponse>>.Ok(paginated, "Recordings retrieved successfully");
        }

        public async Task<ApiResponse<string>> GetCallRecordingSummaryAsync(int? callId = null, int? recordingId = null)
        {
            try
            {
                // 1. Check if a recording exists (prefer recordingId, fallback to callId)
                CallRecording? recording = null;
                if (recordingId.HasValue)
                {
                    recording = await _unitOfWork.CallRecordings.Query()
                        .FirstOrDefaultAsync(r => r.CallRecordingId == recordingId.Value && r.IsActive);
                }
                else if (callId.HasValue)
                {
                    recording = await _unitOfWork.CallRecordings.Query()
                        .FirstOrDefaultAsync(r => r.CallId == callId.Value && r.IsActive);
                }

                if (recording == null)
                {
                    return ApiResponse<string>.Fail("No recording found", 404);
                }

                // 2. If summary already exists, return it
                if (!string.IsNullOrEmpty(recording.AiSummary))
                {
                    return ApiResponse<string>.Ok(recording.AiSummary, "AI summary retrieved from cache");
                }

                // 3. Ensure the physical recording file path is valid
                string physicalPath = recording.FilePath ?? "";
                if (string.IsNullOrEmpty(physicalPath) || !System.IO.File.Exists(physicalPath))
                {
                    // Fallback using the relative FileUrl
                    if (!string.IsNullOrEmpty(recording.FileUrl))
                    {
                        var baseDir = AppDomain.CurrentDomain.BaseDirectory;
                        string relativePath = recording.FileUrl.TrimStart('/');
                        
                        // Try 1: wwwroot/relativePath (IIS standard publish root)
                        physicalPath = System.IO.Path.Combine(baseDir, "wwwroot", relativePath);
                        
                        // Try 2: directly in baseDir (in case baseDir is already wwwroot or relative path is configured)
                        if (!System.IO.File.Exists(physicalPath))
                        {
                            physicalPath = System.IO.Path.Combine(baseDir, relativePath);
                        }
                        
                        // Try 3: check bin/projectRoot fallback (development environment)
                        if (!System.IO.File.Exists(physicalPath))
                        {
                            var projectRoot = System.IO.Directory.GetParent(baseDir)?.Parent?.Parent?.FullName ?? baseDir;
                            physicalPath = System.IO.Path.Combine(projectRoot, "wwwroot", relativePath);
                        }
                    }

                    if (string.IsNullOrEmpty(physicalPath) || !System.IO.File.Exists(physicalPath))
                    {
                        return ApiResponse<string>.Fail($"Recording audio file not found on disk. Tried path: {physicalPath}", 404);
                    }
                    recording.FilePath = physicalPath;
                }

                // 4. Retrieve the active Gemini API Key
                var geminiKey = await _unitOfWork.ApiKeys.Query()
                    .FirstOrDefaultAsync(k => k.ServiceName == "Gemini" && k.IsActive);

                if (geminiKey == null || string.IsNullOrEmpty(geminiKey.Key))
                {
                    return ApiResponse<string>.Fail("Gemini API Key is not configured in the system", 400);
                }

                // 5. Read the audio bytes and convert to Base64
                byte[] audioBytes = await System.IO.File.ReadAllBytesAsync(recording.FilePath);
                string base64Audio = Convert.ToBase64String(audioBytes);

                // 6. Map file extension to standard MIME type
                string extension = System.IO.Path.GetExtension(recording.FilePath).ToLower();
                string mimeType = extension switch
                {
                    ".wav" => "audio/wav",
                    ".m4a" => "audio/x-m4a",
                    ".aac" => "audio/aac",
                    ".ogg" => "audio/ogg",
                    ".flac" => "audio/flac",
                    ".webm" => "audio/webm",
                    _ => "audio/mp3" // Default to audio/mp3
                };

                // 7. Request to Gemini API
                using (var httpClient = new System.Net.Http.HttpClient())
                {
                    httpClient.Timeout = TimeSpan.FromMinutes(3);
                    var requestUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={geminiKey.Key}";

                    var requestBody = new
                    {
                        contents = new[]
                        {
                            new
                            {
                                parts = new object[]
                                {
                                    new
                                    {
                                        inlineData = new
                                        {
                                            mimeType = mimeType,
                                            data = base64Audio
                                        }
                                    },
                                    new
                                    {
                                        text = "You are an AI assistant analyzing a call recording. Listen to the audio and provide:\n" +
                                               "1. Short Summary (2-3 sentences)\n" +
                                               "2. Key Discussion Points (bullet points starting with -)\n" +
                                               "3. Action Items (bullet points starting with -)\n" +
                                               "4. Sentiment (Positive / Neutral / Negative) formatted strictly as 'Sentiment: Positive', 'Sentiment: Neutral', or 'Sentiment: Negative'\n" +
                                               "5. Important Keywords (bullet points starting with -)\n" +
                                               "6. Follow-up Suggestions (bullet points starting with -)"
                                    }
                                }
                            }
                        }
                    };

                    var jsonOptions = new System.Text.Json.JsonSerializerOptions
                    {
                        PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase
                    };
                    string requestJson = System.Text.Json.JsonSerializer.Serialize(requestBody, jsonOptions);
                    using (var httpContent = new System.Net.Http.StringContent(requestJson, System.Text.Encoding.UTF8, "application/json"))
                    {
                        var httpResponse = await httpClient.PostAsync(requestUrl, httpContent);
                        if (!httpResponse.IsSuccessStatusCode)
                        {
                            string errContent = await httpResponse.Content.ReadAsStringAsync();
                            System.Console.Error.WriteLine($"[CallService] Gemini API returned error status {httpResponse.StatusCode}: {errContent}");
                            return ApiResponse<string>.Fail($"Gemini API error: {httpResponse.StatusCode}", (int)httpResponse.StatusCode);
                        }

                        string responseJson = await httpResponse.Content.ReadAsStringAsync();
                        using (var doc = System.Text.Json.JsonDocument.Parse(responseJson))
                        {
                            var root = doc.RootElement;
                            if (root.TryGetProperty("candidates", out var candidates) && 
                                candidates.ValueKind == System.Text.Json.JsonValueKind.Array && 
                                candidates.GetArrayLength() > 0)
                            {
                                var contentObj = candidates[0].GetProperty("content");
                                var parts = contentObj.GetProperty("parts");
                                if (parts.ValueKind == System.Text.Json.JsonValueKind.Array && parts.GetArrayLength() > 0)
                                {
                                    string summaryText = parts[0].GetProperty("text").GetString() ?? "";
                                    
                                    // Cache the summary in the database
                                    recording.AiSummary = summaryText;
                                    recording.UpdatedAt = DateTime.Now;
                                    await _unitOfWork.CallRecordings.UpdateAsync(recording);
                                    await _unitOfWork.SaveChangesAsync();

                                    return ApiResponse<string>.Ok(summaryText, "AI summary generated successfully");
                                }
                            }
                            
                            return ApiResponse<string>.Fail("Failed to parse AI summary from Gemini response", 500);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Console.Error.WriteLine($"[CallService] Exception in GetCallRecordingSummaryAsync: {ex.Message}\n{ex.StackTrace}");
                return ApiResponse<string>.Fail($"Error generating AI summary: {ex.Message}", 500);
            }
        }
    }
}
