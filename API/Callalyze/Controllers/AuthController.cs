using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Auth;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = string.IsNullOrEmpty(request.UserAgent)
                ? (Request.Headers["User-Agent"].ToString() ?? "Unknown")
                : request.UserAgent;

            var result = await _authService.LoginAsync(request, ipAddress, userAgent);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("signup")]
        [AllowAnonymous]
        public async Task<IActionResult> SignUp([FromBody] SignUpRequest request)
        {
            var result = await _authService.SignUpAsync(request);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            var result = await _authService.RefreshTokenAsync(request);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout()
        {
            var employeeIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(employeeIdClaim))
            {
                return Unauthorized(ApiResponse<bool>.Fail("Unauthorized", 401));
            }

            int employeeId = int.Parse(employeeIdClaim);
            var result = await _authService.LogoutAsync(employeeId);
            return StatusCode(result.StatusCode, result);
        }
    }
}
