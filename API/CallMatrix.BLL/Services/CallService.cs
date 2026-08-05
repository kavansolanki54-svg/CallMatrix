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
            var call = await _unitOfWork.Calls.GetByIdAsync(request.CallId);
            if (call == null || !call.IsActive)
            {
                return ApiResponse<CallRecordingResponse>.Fail("Call record not found", 404);
            }

            string? fileUrl = request.FileUrl;
            string? filePath = request.FilePath;

            if (fileStream != null && fileStream.Length > 0)
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
                    System.IO.Directory.CreateDirectory(uploadsFolder);
                }

                var extension = string.IsNullOrEmpty(fileExtension) ? ".mp3" : fileExtension;
                if (!extension.StartsWith('.')) extension = "." + extension;

                var fileName = $"{cleanPhone}_{call.CallId}{extension}";
                filePath = System.IO.Path.Combine(uploadsFolder, fileName);

                using (var targetStream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                {
                    await fileStream.CopyToAsync(targetStream);
                }

                // Construct static file URL
                var relativeFileUrl = System.IO.Path.Combine(relativeDir, fileName).Replace("\\", "/");
                fileUrl = $"/{relativeFileUrl}";
            }

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

            var dto = _mapper.Map<CallRecordingResponse>(entity);
            return ApiResponse<CallRecordingResponse>.Ok(dto, "Call recording saved successfully", 201);
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
                CreatedAt = r.CreatedAt
            }).ToList();

            var paginated = new PaginatedResponse<CallRecordingResponse>(dtos, totalCount, request.Page, request.PageSize);
            return ApiResponse<PaginatedResponse<CallRecordingResponse>>.Ok(paginated, "Recordings retrieved successfully");
        }
    }
}
