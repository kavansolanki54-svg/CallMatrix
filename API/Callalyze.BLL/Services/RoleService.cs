using AutoMapper;
using Callalyze.BLL.Interfaces;
using Callalyze.DAL.Entities;
using Callalyze.DAL.UnitOfWork;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Role;
using Callalyze.DTO.Response.Role;

namespace Callalyze.BLL.Services
{
    public class RoleService : IRoleService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public RoleService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<IEnumerable<RoleResponse>>> GetActiveRolesAsync(int companyId)
        {
            var roles = await _unitOfWork.Roles.GetActiveRolesByCompanyIdAsync(companyId);
            var dtos = _mapper.Map<IEnumerable<RoleResponse>>(roles);
            return ApiResponse<IEnumerable<RoleResponse>>.Ok(dtos, "Roles retrieved successfully");
        }

        public async Task<ApiResponse<RoleResponse>> CreateRoleAsync(CreateRoleRequest request, int createdBy)
        {
            var entity = _mapper.Map<RoleMaster>(request);
            entity.CreatedAt = DateTime.Now;
            entity.CreatedBy = createdBy;
            entity.IsActive = true;

            await _unitOfWork.Roles.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var dto = _mapper.Map<RoleResponse>(entity);
            return ApiResponse<RoleResponse>.Ok(dto, "Role created successfully", 201);
        }

        public async Task<ApiResponse<RoleResponse>> UpdateRoleAsync(UpdateRoleRequest request, int updatedBy)
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(request.RoleId);
            if (role == null || !role.IsActive)
            {
                return ApiResponse<RoleResponse>.Fail("Role not found", 404);
            }

            role.RoleName = request.RoleName;
            role.RoleTypeId = request.RoleTypeId;
            role.Description = request.Description;
            role.UpdatedAt = DateTime.Now;
            role.UpdatedBy = updatedBy;

            await _unitOfWork.Roles.UpdateAsync(role);
            await _unitOfWork.SaveChangesAsync();

            var dto = _mapper.Map<RoleResponse>(role);
            return ApiResponse<RoleResponse>.Ok(dto, "Role updated successfully");
        }

        public async Task<ApiResponse<bool>> DeleteRoleAsync(int roleId, int deletedBy)
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(roleId);
            if (role == null || !role.IsActive)
            {
                return ApiResponse<bool>.Fail("Role not found", 404);
            }

            await _unitOfWork.Roles.SoftDeleteAsync(roleId, deletedBy);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Role deleted successfully");
        }

        public async Task<ApiResponse<RolePermissionMatrixResponse>> GetRolePermissionMatrixAsync(int roleId, int companyId)
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(roleId);
            if (role == null || !role.IsActive)
            {
                return ApiResponse<RolePermissionMatrixResponse>.Fail("Role not found", 404);
            }

            var allMenus = await _unitOfWork.Menus.GetAllAsync();
            var tenantMenus = allMenus.Where(m => m.IsActive && (m.CompanyId == null || m.CompanyId == companyId)).ToList();
            var existingPermissions = await _unitOfWork.RolePermissions.GetPermissionsByRoleIdAsync(roleId);

            var items = new List<RolePermissionItemResponse>();
            foreach (var menu in tenantMenus)
            {
                var perm = existingPermissions.FirstOrDefault(p => p.MenuId == menu.MenuId);
                items.Add(new RolePermissionItemResponse
                {
                    RolePermissionId = perm?.PermissionId ?? 0,
                    MenuId = menu.MenuId,
                    MenuName = menu.MenuName,
                    ParentId = menu.ParentId,
                    CanView = perm?.CanView ?? false,
                    CanAdd = perm?.CanAdd ?? false,
                    CanEdit = perm?.CanEdit ?? false,
                    CanDelete = perm?.CanDelete ?? false,
                    CanExport = perm?.CanExport ?? false,
                    CanPrint = perm?.CanPrint ?? false,
                    CanApprove = perm?.CanApprove ?? false
                });
            }

            var result = new RolePermissionMatrixResponse
            {
                RoleId = role.RoleId,
                RoleName = role.RoleName,
                Permissions = items
            };

            return ApiResponse<RolePermissionMatrixResponse>.Ok(result, "Role permission matrix retrieved successfully");
        }

        public async Task<ApiResponse<bool>> UpdateRolePermissionsAsync(UpdateRolePermissionsRequest request, int updatedBy)
        {
            var role = await _unitOfWork.Roles.GetByIdAsync(request.RoleId);
            if (role == null || !role.IsActive)
            {
                return ApiResponse<bool>.Fail("Role not found", 404);
            }

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var permissionTuples = request.Permissions
                    .Select(p => (p.MenuId, p.CanView, p.CanAdd, p.CanEdit, p.CanDelete, p.CanExport, p.CanPrint, p.CanApprove))
                    .ToList();

                await _unitOfWork.RolePermissions.UpdatePermissionsForRoleAsync(request.RoleId, permissionTuples, updatedBy);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();

                return ApiResponse<bool>.Ok(true, "Role permission matrix updated successfully");
            }
            catch
            {
                await _unitOfWork.RollbackTransactionAsync();
                throw;
            }
        }
    }
}
