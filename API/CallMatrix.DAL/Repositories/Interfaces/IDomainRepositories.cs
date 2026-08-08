using CallMatrix.DAL.Entities;
using CallMatrix.DAL.Repositories.Generic;

namespace CallMatrix.DAL.Repositories.Interfaces
{
    public interface ICompanyRepository : IGenericRepository<CompanyMaster>
    {
    }

    public interface IBranchRepository : IGenericRepository<BranchMaster>
    {
    }

    public interface IDepartmentRepository : IGenericRepository<DepartmentMaster>
    {
    }

    public interface IDesignationRepository : IGenericRepository<DesignationMaster>
    {
    }

    public interface IEmployeeRepository : IGenericRepository<EmployeeMaster>
    {
        Task<EmployeeMaster?> GetByEmailAsync(string email);
        Task<EmployeeMaster?> GetByEmployeeCodeAsync(string employeeCode);
        Task<IEnumerable<int>> GetAssignedBranchIdsAsync(int employeeId);
        Task UpdateEmployeeBranchesAsync(int employeeId, List<int> branchIds, int updatedBy);
    }

    public interface IRoleRepository : IGenericRepository<RoleMaster>
    {
        Task<IEnumerable<RoleMaster>> GetActiveRolesByCompanyIdAsync(int companyId);
    }

    public interface IMenuRepository : IGenericRepository<MenuMaster>
    {
        Task<IEnumerable<MenuMaster>> GetMenusByRoleIdAsync(int roleId, int companyId);
        Task<IEnumerable<MenuMaster>> GetTenantMenusAsync(int companyId);
    }

    public interface IRolePermissionRepository : IGenericRepository<RolePermission>
    {
        Task<IEnumerable<RolePermission>> GetPermissionsByRoleIdAsync(int roleId);
        Task<RolePermission?> GetPermissionByRoleAndMenuAsync(int roleId, int menuId);
        Task UpdatePermissionsForRoleAsync(int roleId, List<(int MenuId, bool CanView, bool CanAdd, bool CanEdit, bool CanDelete, bool CanExport, bool CanPrint, bool CanApprove)> permissions, int updatedBy);
    }

    public interface IRefreshTokenRepository : IGenericRepository<RefreshToken>
    {
        Task<RefreshToken?> GetByTokenAsync(string token);
        Task RevokeTokensByEmployeeIdAsync(int employeeId);
    }

    public interface ILoginHistoryRepository : IGenericRepository<LoginHistory>
    {
        Task LogLoginAsync(LoginHistory history);
        Task LogLogoutAsync(int employeeId);
    }

    public interface IEnumTypeRepository : IGenericRepository<EnumMaster>
    {
        Task<IEnumerable<EnumMaster>> GetEnumTypesByCategoryIdAsync(short categoryId);
    }

    public interface IApiKeyRepository : IGenericRepository<ApiKeySetting>
    {
    }
}
