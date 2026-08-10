using System.Security.Claims;
using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Callalyze.Filters
{
    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
    public class RequirePermissionAttribute : TypeFilterAttribute
    {
        public RequirePermissionAttribute(string menuName, string permissionType)
            : base(typeof(RequirePermissionFilter))
        {
            Arguments = new object[] { menuName, permissionType };
        }
    }

    public class RequirePermissionFilter : IAsyncActionFilter
    {
        private readonly string _menuName;
        private readonly string _permissionType;
        private readonly IMenuService _menuService;

        public RequirePermissionFilter(string menuName, string permissionType, IMenuService menuService)
        {
            _menuName = menuName;
            _permissionType = permissionType;
            _menuService = menuService;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var user = context.HttpContext.User;
            if (user?.Identity == null || !user.Identity.IsAuthenticated)
            {
                context.Result = new UnauthorizedObjectResult(ApiResponse<object>.Fail("Unauthorized access", 401));
                return;
            }

            var roleIdClaim = user.FindFirst("RoleId")?.Value;
            var companyIdClaim = user.FindFirst("CompanyId")?.Value;
            var isTenantClaim = user.FindFirst("Tenant")?.Value;
            bool isTenant = isTenantClaim == "1";

            if (string.IsNullOrEmpty(companyIdClaim))
            {
                context.Result = new ObjectResult(ApiResponse<object>.Fail("Access denied: Missing Company claims", 403)) { StatusCode = 403 };
                return;
            }

            if (!isTenant && string.IsNullOrEmpty(roleIdClaim))
            {
                context.Result = new ObjectResult(ApiResponse<object>.Fail("Access denied: Missing Role claims", 403)) { StatusCode = 403 };
                return;
            }

            int roleId = string.IsNullOrEmpty(roleIdClaim) ? 0 : int.Parse(roleIdClaim);
            int companyId = int.Parse(companyIdClaim);

            var menuTreeResult = await _menuService.GetMenuTreeByRoleIdAsync(roleId, companyId, isTenant);
            if (!menuTreeResult.Success || menuTreeResult.Data == null)
            {
                context.Result = new ObjectResult(ApiResponse<object>.Fail("Access denied: Permissions not found", 403)) { StatusCode = 403 };
                return;
            }

            bool hasPermission = CheckPermissionInTree(menuTreeResult.Data, _menuName, _permissionType);

            if (!hasPermission)
            {
                context.Result = new ObjectResult(ApiResponse<object>.Fail($"Access denied: Missing {_permissionType} permission on '{_menuName}'", 403)) { StatusCode = 403 };
                return;
            }

            await next();
        }

        private bool CheckPermissionInTree(List<DTO.Response.Menu.MenuTreeResponse> nodes, string menuName, string permissionType)
        {
            foreach (var node in nodes)
            {
                if (string.Equals(node.MenuName, menuName, StringComparison.OrdinalIgnoreCase))
                {
                    return GetPermissionFlag(node.Permissions, permissionType);
                }

                if (node.Children.Any())
                {
                    bool found = CheckPermissionInTree(node.Children, menuName, permissionType);
                    if (found) return true;
                }
            }
            return false;
        }

        private bool GetPermissionFlag(DTO.Response.Menu.MenuPermissionDto perms, string permissionType)
        {
            return permissionType.ToLower() switch
            {
                "canview" => perms.CanView,
                "canadd" => perms.CanAdd,
                "canedit" => perms.CanEdit,
                "candelete" => perms.CanDelete,
                "canexport" => perms.CanExport,
                "canimport" => perms.CanImport,
                "canprint" => perms.CanPrint,
                "canupload" => perms.CanUpload,
                "candownload" => perms.CanDownload,
                "canapprove" => perms.CanApprove,
                "canassign" => perms.CanAssign,
                _ => false
            };
        }
    }
}
