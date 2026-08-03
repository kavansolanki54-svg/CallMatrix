using System.Security.Claims;
using CallMatrix.BLL.Interfaces;
using CallMatrix.DTO.Request.Organization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CallMatrix.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class DesignationsController : ControllerBase
    {
        private readonly IOrganizationService _organizationService;

        public DesignationsController(IOrganizationService organizationService)
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
            var result = await _organizationService.GetDesignationsAsync(companyId, search);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPost]
        public async Task<IActionResult> Post([FromBody] CreateDesignationRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.CreateDesignationAsync(request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Put(int id, [FromBody] UpdateDesignationRequest request)
        {
            var userId = GetUserId();
            var result = await _organizationService.UpdateDesignationAsync(id, request, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var userId = GetUserId();
            var result = await _organizationService.DeleteDesignationAsync(id, userId);
            if (result.Success)
                return Ok(result);
            return BadRequest(result);
        }
    }
}
