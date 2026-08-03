using CallMatrix.BLL.Interfaces;
using CallMatrix.DTO.Request.Role;
using CallMatrix.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CallMatrix.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RolesController : ControllerBase
    {
        private readonly IRoleService _roleService;

        public RolesController(IRoleService roleService)
        {
            _roleService = roleService;
        }

        [HttpGet]
        [RequirePermission("Role Master", "CanView")]
        public async Task<IActionResult> GetRoles()
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _roleService.GetActiveRolesAsync(companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Role Master", "CanAdd")]
        public async Task<IActionResult> CreateRole([FromBody] CreateRoleRequest request)
        {
            int createdBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _roleService.CreateRoleAsync(request, createdBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut]
        [RequirePermission("Role Master", "CanEdit")]
        public async Task<IActionResult> UpdateRole([FromBody] UpdateRoleRequest request)
        {
            int updatedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _roleService.UpdateRoleAsync(request, updatedBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpDelete("{id}")]
        [RequirePermission("Role Master", "CanDelete")]
        public async Task<IActionResult> DeleteRole(int id)
        {
            int deletedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _roleService.DeleteRoleAsync(id, deletedBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("{roleId}/permissions")]
        [RequirePermission("Access Control", "CanView")]
        public async Task<IActionResult> GetPermissions(int roleId)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _roleService.GetRolePermissionMatrixAsync(roleId, companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut("permissions")]
        [RequirePermission("Access Control", "CanEdit")]
        public async Task<IActionResult> UpdatePermissions([FromBody] UpdateRolePermissionsRequest request)
        {
            int updatedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _roleService.UpdateRolePermissionsAsync(request, updatedBy);
            return StatusCode(result.StatusCode, result);
        }
    }
}
