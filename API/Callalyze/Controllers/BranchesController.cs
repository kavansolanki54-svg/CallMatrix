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
    public class BranchesController : ControllerBase
    {
        private readonly IOrganizationService _organizationService;

        public BranchesController(IOrganizationService organizationService)
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
            var result = await _organizationService.GetBranchesAsync(companyId, search);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPost]
        public async Task<IActionResult> Post([FromBody] CreateBranchRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.CreateBranchAsync(request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Put(int id, [FromBody] UpdateBranchRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.UpdateBranchAsync(id, request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var userId = GetUserId();
            var result = await _organizationService.DeleteBranchAsync(id, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }
    }
}
