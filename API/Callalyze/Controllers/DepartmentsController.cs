using System.Security.Claims;
using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Request.Organization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class DepartmentsController : ControllerBase
    {
        private readonly IOrganizationService _organizationService;

        public DepartmentsController(IOrganizationService organizationService)
        {
            _organizationService = organizationService;
        }

        private int GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdClaim, out int userId) ? userId : 0;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] int companyId = 1, [FromQuery] string search = "")
        {
            var result = await _organizationService.GetDepartmentsAsync(companyId, search);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPost]
        public async Task<IActionResult> Post([FromBody] CreateDepartmentRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.CreateDepartmentAsync(request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Put(int id, [FromBody] UpdateDepartmentRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.UpdateDepartmentAsync(id, request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var userId = GetUserId();
            var result = await _organizationService.DeleteDepartmentAsync(id, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }
    }
}
