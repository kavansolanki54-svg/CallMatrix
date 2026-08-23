using Callalyze.DAL.Data;
using Callalyze.DAL.Entities;
using Callalyze.DTO.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LogsController : ControllerBase
    {
        private readonly CallalyzeDbContext _context;

        public LogsController(CallalyzeDbContext context)
        {
            _context = context;
        }

        [HttpPost("error")]
        [AllowAnonymous]
        public async Task<IActionResult> LogError([FromBody] LogErrorRequest request)
        {
            try
            {
                var employeeIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var companyIdStr = User.FindFirst("CompanyId")?.Value;

                int? employeeId = string.IsNullOrEmpty(employeeIdStr) ? null : int.Parse(employeeIdStr);
                int? companyId = string.IsNullOrEmpty(companyIdStr) ? null : int.Parse(companyIdStr);

                var errorLog = new ErrorLog
                {
                    EmployeeId = employeeId,
                    CompanyId = companyId,
                    ErrorMessage = request.ErrorMessage,
                    StackTrace = request.StackTrace,
                    Path = request.Path ?? "MobileApp",
                    Method = request.Method ?? "POST",
                    QueryString = request.QueryString,
                    Ipaddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = request.UserAgent ?? (Request.Headers.ContainsKey("User-Agent") ? Request.Headers["User-Agent"].ToString() : "MobileApp"),
                    CreatedAt = DateTime.Now,
                    IsActive = true
                };

                _context.ErrorLogs.Add(errorLog);
                await _context.SaveChangesAsync();

                return Ok(ApiResponse<bool>.Ok(true, "Error logged successfully"));
            }
            catch (Exception ex)
            {
                return StatusCode(500, ApiResponse<bool>.Fail($"Failed to log error: {ex.Message}"));
            }
        }
    }

    public class LogErrorRequest
    {
        public string ErrorMessage { get; set; } = null!;
        public string? StackTrace { get; set; }
        public string? Path { get; set; }
        public string? Method { get; set; }
        public string? QueryString { get; set; }
        public string? UserAgent { get; set; }
    }
}
