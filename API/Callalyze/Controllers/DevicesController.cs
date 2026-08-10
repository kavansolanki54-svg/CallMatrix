using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Device;
using Callalyze.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DevicesController : ControllerBase
    {
        private readonly IDeviceService _deviceService;

        public DevicesController(IDeviceService deviceService)
        {
            _deviceService = deviceService;
        }

        [HttpGet]
        [RequirePermission("Device Management", "CanView")]
        public async Task<IActionResult> GetDevices([FromQuery] PaginationRequest request)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _deviceService.GetDevicesAsync(request, companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _deviceService.RegisterDeviceAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("ping")]
        public async Task<IActionResult> UpdatePing([FromBody] UpdateDevicePingRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _deviceService.UpdatePingAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut("approve")]
        [RequirePermission("Device Management", "CanEdit")]
        public async Task<IActionResult> ApproveDevice([FromBody] ApproveDeviceRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _deviceService.ApproveDeviceAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut("block")]
        [RequirePermission("Device Management", "CanEdit")]
        public async Task<IActionResult> BlockDevice([FromBody] BlockDeviceRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _deviceService.BlockDeviceAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }
    }
}
