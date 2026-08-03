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
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _callService.GetCallsAsync(request, companyId);
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
        public async Task<IActionResult> UploadCallRecording([FromBody] UploadCallRecordingRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _callService.SaveCallRecordingAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("analytics")]
        [RequirePermission("Call Analytics", "CanView")]
        public async Task<IActionResult> GetAnalytics([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _callService.GetAnalyticsSummaryAsync(companyId, startDate, endDate);
            return StatusCode(result.StatusCode, result);
        }
    }
}
