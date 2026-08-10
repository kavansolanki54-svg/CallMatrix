using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.CRM;
using Callalyze.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class LeadsController : ControllerBase
    {
        private readonly ILeadService _leadService;

        public LeadsController(ILeadService leadService)
        {
            _leadService = leadService;
        }

        [HttpGet]
        [RequirePermission("Lead", "CanView")]
        public async Task<IActionResult> GetLeads([FromQuery] PaginationRequest request)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _leadService.GetLeadsAsync(request, companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Lead", "CanAdd")]
        public async Task<IActionResult> CreateLead([FromBody] CreateLeadRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _leadService.CreateLeadAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut("status")]
        [RequirePermission("Lead", "CanEdit")]
        public async Task<IActionResult> UpdateStatus([FromBody] UpdateLeadStatusRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _leadService.UpdateLeadStatusAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut("assign")]
        [RequirePermission("Lead", "CanAssign")]
        public async Task<IActionResult> AssignLead([FromBody] AssignLeadRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _leadService.AssignLeadAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("{id}/convert")]
        [RequirePermission("Lead", "CanEdit")]
        public async Task<IActionResult> ConvertToCustomer(int id)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _leadService.ConvertLeadToCustomerAsync(id, employeeId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("{id}/timeline")]
        [RequirePermission("Lead", "CanView")]
        public async Task<IActionResult> GetTimeline(int id)
        {
            var result = await _leadService.GetLeadTimelineAsync(id);
            return StatusCode(result.StatusCode, result);
        }
    }
}
