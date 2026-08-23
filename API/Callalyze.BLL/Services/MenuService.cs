using Callalyze.BLL.Interfaces;
using Callalyze.DAL.Entities;
using Callalyze.DAL.UnitOfWork;
using Callalyze.DTO.Common;
using Callalyze.DTO.Response.Menu;

namespace Callalyze.BLL.Services
{
    public class MenuService : IMenuService
    {
        private readonly IUnitOfWork _unitOfWork;

        public MenuService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ApiResponse<List<MenuTreeResponse>>> GetMenuTreeByRoleIdAsync(int roleId, int companyId, bool isTenant = false)
        {
            IEnumerable<MenuMaster> menus;
            IEnumerable<RolePermission> permissions = new List<RolePermission>();

            if (isTenant)
            {
                menus = await _unitOfWork.Menus.GetTenantMenusAsync(companyId);
            }
            else
            {
                menus = await _unitOfWork.Menus.GetMenusByRoleIdAsync(roleId, companyId);
                permissions = await _unitOfWork.RolePermissions.GetPermissionsByRoleIdAsync(roleId);
            }

            var permDict = permissions.ToDictionary(p => p.MenuId);
            var menuList = menus.ToList();

            // Build hierarchical tree
            var rootNodes = menuList
                .Where(m => m.ParentId == null)
                .Select(m => MapToTreeNode(m, menuList, permDict, isTenant))
                .OrderBy(m => m.SortOrder)
                .ToList();

            return ApiResponse<List<MenuTreeResponse>>.Ok(rootNodes, "Menu tree retrieved successfully");
        }

        private MenuTreeResponse MapToTreeNode(MenuMaster menu, List<MenuMaster> allMenus, Dictionary<int, RolePermission> permDict, bool isTenant)
        {
            var dto = new MenuTreeResponse
            {
                MenuId = menu.MenuId,
                CompanyId = menu.CompanyId,
                MenuName = menu.MenuName,
                Icon = menu.Icon,
                Url = menu.Url,
                ParentId = menu.ParentId,
                SortOrder = menu.SortOrder,
                Permissions = isTenant ? new MenuPermissionDto { CanView = true, CanAdd = true, CanEdit = true, CanDelete = true, CanExport = true, CanImport = true, CanPrint = true, CanUpload = true, CanDownload = true, CanApprove = true, CanAssign = true } : (permDict.TryGetValue(menu.MenuId, out var perm)
                    ? new MenuPermissionDto
                    {
                        CanView = perm.CanView,
                        CanAdd = perm.CanAdd,
                        CanEdit = perm.CanEdit,
                        CanDelete = perm.CanDelete,
                        CanExport = perm.CanExport,
                        CanImport = perm.CanImport,
                        CanPrint = perm.CanPrint,
                        CanUpload = perm.CanUpload,
                        CanDownload = perm.CanDownload,
                        CanApprove = perm.CanApprove,
                        CanAssign = perm.CanAssign
                    }
                    : new MenuPermissionDto()),
                Children = allMenus
                    .Where(m => m.ParentId == menu.MenuId)
                    .Select(m => MapToTreeNode(m, allMenus, permDict, isTenant))
                    .OrderBy(m => m.SortOrder)
                    .ToList()
            };

            return dto;
        }
        public async Task<ApiResponse<IEnumerable<MenuResponse>>> GetAllMenusAsync(int companyId)
        {
            var menus = await _unitOfWork.Menus.GetAllAsync();
            var tenantMenus = menus.Where(m => m.IsActive && (m.CompanyId == null || m.CompanyId == companyId)).OrderBy(m => m.SortOrder).ToList();
            
            var responses = tenantMenus.Select(m => new MenuResponse
            {
                MenuId = m.MenuId,
                CompanyId = m.CompanyId,
                MenuName = m.MenuName,
                Icon = m.Icon,
                Url = m.Url,
                ParentId = m.ParentId,
                ParentName = tenantMenus.FirstOrDefault(p => p.MenuId == m.ParentId)?.MenuName,
                SortOrder = m.SortOrder,
                IsActive = m.IsActive,
                CreatedAt = m.CreatedAt
            }).ToList();

            return ApiResponse<IEnumerable<MenuResponse>>.Ok(responses, "Menus retrieved successfully");
        }

        public async Task<ApiResponse<MenuResponse>> CreateMenuAsync(DTO.Request.Menu.CreateMenuRequest request, int createdBy)
        {
            var entity = new MenuMaster
            {
                CompanyId = request.CompanyId,
                MenuName = request.MenuName,
                Icon = request.Icon,
                Url = request.Url,
                ParentId = request.ParentId,
                SortOrder = request.SortOrder,
                IsActive = true,
                CreatedAt = DateTime.Now,
                CreatedBy = createdBy
            };

            await _unitOfWork.Menus.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var response = new MenuResponse
            {
                MenuId = entity.MenuId,
                CompanyId = entity.CompanyId,
                MenuName = entity.MenuName,
                Icon = entity.Icon,
                Url = entity.Url,
                ParentId = entity.ParentId,
                SortOrder = entity.SortOrder,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt
            };

            return ApiResponse<MenuResponse>.Ok(response, "Menu created successfully", 201);
        }

        public async Task<ApiResponse<MenuResponse>> UpdateMenuAsync(DTO.Request.Menu.UpdateMenuRequest request, int updatedBy)
        {
            var entity = await _unitOfWork.Menus.GetByIdAsync(request.MenuId);
            if (entity == null)
            {
                return ApiResponse<MenuResponse>.Fail("Menu not found", 404);
            }

            entity.MenuName = request.MenuName;
            entity.Icon = request.Icon;
            entity.Url = request.Url;
            entity.ParentId = request.ParentId;
            entity.SortOrder = request.SortOrder;
            entity.IsActive = request.IsActive;
            entity.UpdatedAt = DateTime.Now;
            entity.UpdatedBy = updatedBy;

            await _unitOfWork.Menus.UpdateAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var response = new MenuResponse
            {
                MenuId = entity.MenuId,
                CompanyId = entity.CompanyId,
                MenuName = entity.MenuName,
                Icon = entity.Icon,
                Url = entity.Url,
                ParentId = entity.ParentId,
                SortOrder = entity.SortOrder,
                IsActive = entity.IsActive,
                CreatedAt = entity.CreatedAt
            };

            return ApiResponse<MenuResponse>.Ok(response, "Menu updated successfully");
        }

        public async Task<ApiResponse<bool>> DeleteMenuAsync(int menuId, int deletedBy)
        {
            var entity = await _unitOfWork.Menus.GetByIdAsync(menuId);
            if (entity == null)
            {
                return ApiResponse<bool>.Fail("Menu not found", 404);
            }

            await _unitOfWork.Menus.SoftDeleteAsync(menuId, deletedBy);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Menu deleted successfully");
        }
    }
}
