using AutoMapper;
using CallMatrix.BLL.Interfaces;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Calls;
using CallMatrix.DTO.Response.Calls;

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

        public async Task<ApiResponse<PaginatedResponse<CallLogResponse>>> GetCallsAsync(PaginationRequest request, int companyId)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;

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
                foreach (var callDto in request.Calls)
                {
                    var entity = _mapper.Map<CallMaster>(callDto);
                    entity.CompanyId = request.CompanyId;
                    entity.DeviceId = request.DeviceId;
                    entity.EmployeeId = employeeId;
                    entity.SyncedAt = DateTime.Now;
                    entity.CreatedAt = DateTime.Now;
                    entity.CreatedBy = employeeId;
                    entity.IsActive = true;

                    await _unitOfWork.Calls.AddAsync(entity);
                }

                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();

                return ApiResponse<bool>.Ok(true, $"{request.Calls.Count} call logs synchronized successfully");
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
                var uploadsFolder = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "wwwroot", "recordings");
                if (!System.IO.Directory.Exists(uploadsFolder))
                {
                    System.IO.Directory.CreateDirectory(uploadsFolder);
                }

                var extension = string.IsNullOrEmpty(fileExtension) ? ".mp3" : fileExtension;
                if (!extension.StartsWith('.')) extension = "." + extension;

                var uniqueFileName = $"{Guid.NewGuid()}_{request.FileName}{extension}";
                filePath = System.IO.Path.Combine(uploadsFolder, uniqueFileName);

                using (var targetStream = new System.IO.FileStream(filePath, System.IO.FileMode.Create))
                {
                    await fileStream.CopyToAsync(targetStream);
                }

                fileUrl = $"/recordings/{uniqueFileName}";
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

        public async Task<ApiResponse<CallAnalyticsSummaryResponse>> GetAnalyticsSummaryAsync(int companyId, DateTime? startDate, DateTime? endDate)
        {
            var calls = await _unitOfWork.Calls.GetCallsByCompanyIdAsync(companyId);

            if (startDate.HasValue)
                calls = calls.Where(c => c.CallDateTime >= startDate.Value);

            if (endDate.HasValue)
                calls = calls.Where(c => c.CallDateTime <= endDate.Value);

            var callList = calls.ToList();
            int totalCount = callList.Count;

            int incoming = callList.Count(c => c.CallType.Equals("Incoming", StringComparison.OrdinalIgnoreCase));
            int outgoing = callList.Count(c => c.CallType.Equals("Outgoing", StringComparison.OrdinalIgnoreCase));
            int missed = callList.Count(c => c.CallType.Equals("Missed", StringComparison.OrdinalIgnoreCase));

            long totalDuration = callList.Sum(c => (long)(c.Duration ?? 0));
            double avgDuration = totalCount > 0 ? (double)totalDuration / totalCount : 0;

            var recordings = await _unitOfWork.CallRecordings.GetRecordingsByCompanyIdAsync(companyId);

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
    }
}
