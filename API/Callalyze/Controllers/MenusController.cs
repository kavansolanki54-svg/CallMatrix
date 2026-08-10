using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MenusController : ControllerBase
    {
        private readonly IMenuService _menuService;

        public MenusController(IMenuService menuService)
        {
            _menuService = menuService;
        }

        [HttpGet("tree")]
        public async Task<IActionResult> GetMenuTree()
        {
            var roleIdClaim = User.FindFirst("RoleId")?.Value;
            var companyIdClaim = User.FindFirst("CompanyId")?.Value;
            var tenantClaim = User.FindFirst("Tenant")?.Value;

            if (string.IsNullOrEmpty(companyIdClaim))
            {
                return Forbidden(ApiResponse<object>.Fail("Missing company claims", 403));
            }

            int companyId = int.Parse(companyIdClaim);
            bool isTenant = tenantClaim == "1";
            int roleId = string.IsNullOrEmpty(roleIdClaim) ? 0 : int.Parse(roleIdClaim);

            if (!isTenant && roleId == 0)
            {
                return Forbidden(ApiResponse<object>.Fail("Missing role claim", 403));
            }

            var result = await _menuService.GetMenuTreeByRoleIdAsync(roleId, companyId, isTenant);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet]
        [RequirePermission("Menus Master", "CanView")]
        public async Task<IActionResult> GetAllMenus()
        {
            var companyIdClaim = User.FindFirst("CompanyId")?.Value;
            if (string.IsNullOrEmpty(companyIdClaim)) return Forbidden(ApiResponse<object>.Fail("Missing company claim", 403));
            
            int companyId = int.Parse(companyIdClaim);
            var result = await _menuService.GetAllMenusAsync(companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Menus Master", "CanAdd")]
        public async Task<IActionResult> CreateMenu([FromBody] DTO.Request.Menu.CreateMenuRequest request)
        {
            int createdBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _menuService.CreateMenuAsync(request, createdBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut]
        [RequirePermission("Menus Master", "CanEdit")]
        public async Task<IActionResult> UpdateMenu([FromBody] DTO.Request.Menu.UpdateMenuRequest request)
        {
            int updatedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _menuService.UpdateMenuAsync(request, updatedBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpDelete("{id}")]
        [RequirePermission("Menus Master", "CanDelete")]
        public async Task<IActionResult> DeleteMenu(int id)
        {
            int deletedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _menuService.DeleteMenuAsync(id, deletedBy);
            return StatusCode(result.StatusCode, result);
        }

        private IActionResult Forbidden(object value) => new ObjectResult(value) { StatusCode = 403 };
    }
}
