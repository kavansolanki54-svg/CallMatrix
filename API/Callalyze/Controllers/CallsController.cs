using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Calls;
using Callalyze.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CallsController : ControllerBase
    {
        private readonly ICallService _callService;

        public CallsController(ICallService callService)
        {
            _callService = callService;
        }

        [HttpGet]
        [RequirePermission("Call Logs", "CanView")]
        public async Task<IActionResult> GetCalls([FromQuery] PaginationRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            bool isAdmin = roleClaim == "Company Admin" || roleClaim == "Super Admin" || User.FindFirst("Tenant")?.Value == "1";
            int? employeeIdFilter = isAdmin ? null : (int?)employeeId;

            var result = await _callService.GetCallsAsync(request, companyId, employeeIdFilter);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("recordings")]
        [RequirePermission("Call Recordings", "CanView")]
        public async Task<IActionResult> GetRecordings([FromQuery] PaginationRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            bool isAdmin = roleClaim == "Company Admin" || roleClaim == "Super Admin" || User.FindFirst("Tenant")?.Value == "1";
            int? employeeIdFilter = isAdmin ? null : (int?)employeeId;

            var result = await _callService.GetRecordingsAsync(request, companyId, employeeIdFilter);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Call Logs", "CanAdd")]
        public async Task<IActionResult> CreateCallLog([FromBody] CreateCallLogRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _callService.CreateCallLogAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("sync")]
        [RequirePermission("Call Logs", "CanAdd")]
        public async Task<IActionResult> SyncCalls([FromBody] SyncCallsRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _callService.SyncCallsAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("recording")]
        public async Task<IActionResult> UploadCallRecording([FromForm] UploadCallRecordingRequest request, IFormFile? file)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            System.Console.WriteLine($"[CallsController] UploadCallRecording received: employeeId={employeeId}, companyId={companyId}, CallId={request.CallId}, fileName={request.FileName}, fileSize={request.FileSize}, filePresent={file != null}, fileLength={file?.Length ?? 0}");
            if (file == null)
            {
                System.Console.Error.WriteLine($"[CallsController] UploadCallRecording warning: no file attachment received in multipart/form-data request for CallId={request.CallId}");
            }

            System.IO.Stream? fileStream = file?.OpenReadStream();
            string? fileExtension = file != null ? System.IO.Path.GetExtension(file.FileName) : null;

            var result = await _callService.SaveCallRecordingAsync(request, fileStream, fileExtension, employeeId);
            if (result.StatusCode >= 400)
            {
                System.Console.Error.WriteLine($"[CallsController] UploadCallRecording response status is error: {result.StatusCode} - {result.Message}");
            }
            else
            {
                System.Console.WriteLine($"[CallsController] UploadCallRecording response status is success: {result.StatusCode} - {result.Message}");
            }
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("analytics")]
        [RequirePermission("Call Analytics", "CanView")]
        public async Task<IActionResult> GetAnalytics([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            bool isAdmin = roleClaim == "Company Admin" || roleClaim == "Super Admin" || User.FindFirst("Tenant")?.Value == "1";
            int? employeeIdFilter = isAdmin ? null : (int?)employeeId;

            // Default to Today's date range if not specified
            var start = startDate ?? DateTime.Today;
            var end = endDate ?? DateTime.Today.AddDays(1).AddTicks(-1);

            var result = await _callService.GetAnalyticsSummaryAsync(companyId, start, end, employeeIdFilter);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("dashboard")]
        [RequirePermission("Call Analytics", "CanView")]
        public async Task<IActionResult> GetDashboardSummary([FromQuery] DateTime? date, [FromQuery] int? employeeId)
        {
            int currentEmployeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var roleClaim = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            bool isAdmin = roleClaim == "Company Admin" || roleClaim == "Super Admin" || User.FindFirst("Tenant")?.Value == "1";
            
            // Admins can filter by any selected employeeId; regular users are locked to their own.
            int? employeeIdFilter = isAdmin ? employeeId : currentEmployeeId;

            // Default to Current Date (Today's date) if no date is provided
            var targetDate = date ?? DateTime.Today;

            var result = await _callService.GetDashboardSummaryAsync(companyId, targetDate, employeeIdFilter);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("{callId:int}/summary")]
        [RequirePermission("Call Recordings", "CanView")]
        public async Task<IActionResult> GetCallRecordingSummary([FromRoute] int callId)
        {
            var result = await _callService.GetCallRecordingSummaryAsync(callId: callId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("recordings/{recordingId:int}/summary")]
        [RequirePermission("Call Recordings", "CanView")]
        public async Task<IActionResult> GetCallRecordingSummaryByRecording([FromRoute] int recordingId)
        {
            var result = await _callService.GetCallRecordingSummaryAsync(recordingId: recordingId);
            return StatusCode(result.StatusCode, result);
        }
    }
}
