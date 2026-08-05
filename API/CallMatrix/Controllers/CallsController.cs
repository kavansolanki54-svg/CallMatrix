using CallMatrix.BLL.Interfaces;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Calls;
using CallMatrix.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CallMatrix.Controllers
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
        [RequirePermission("Call Recordings", "CanUpload")]
        public async Task<IActionResult> UploadCallRecording([FromForm] UploadCallRecordingRequest request, IFormFile? file)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            System.IO.Stream? fileStream = file?.OpenReadStream();
            string? fileExtension = file != null ? System.IO.Path.GetExtension(file.FileName) : null;

            var result = await _callService.SaveCallRecordingAsync(request, fileStream, fileExtension, employeeId);
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
    }
}
