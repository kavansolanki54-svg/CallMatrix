using Callalyze.DAL.Connection;
using Callalyze.DAL.Data;
using Callalyze.DAL.Entities;
using Callalyze.DAL.Repositories.Generic;
using Callalyze.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Callalyze.DAL.Repositories.Implementations
{
    public class CompanyRepository : GenericRepository<CompanyMaster>, ICompanyRepository
    {
        public CompanyRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }
    }

    public class BranchRepository : GenericRepository<BranchMaster>, IBranchRepository
    {
        public BranchRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }
    }

    public class DepartmentRepository : GenericRepository<DepartmentMaster>, IDepartmentRepository
    {
        public DepartmentRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }
    }

    public class DesignationRepository : GenericRepository<DesignationMaster>, IDesignationRepository
    {
        public DesignationRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }
    }

    public class EmployeeRepository : GenericRepository<EmployeeMaster>, IEmployeeRepository
    {
        public EmployeeRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<EmployeeMaster?> GetByEmailAsync(string email)
        {
            return await _context.EmployeeMasters
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.Email == email && e.IsActive);
        }

        public async Task<EmployeeMaster?> GetByEmployeeCodeAsync(string employeeCode)
        {
            return await _context.EmployeeMasters
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.EmployeeCode == employeeCode && e.IsActive);
        }

        public async Task<IEnumerable<int>> GetAssignedBranchIdsAsync(int employeeId)
        {
            return await _context.EmployeeBranches
                .AsNoTracking()
                .Where(eb => eb.EmployeeId == employeeId && eb.IsActive)
                .Select(eb => eb.BranchId)
                .ToListAsync();
        }

        public async Task UpdateEmployeeBranchesAsync(int employeeId, List<int> branchIds, int updatedBy)
        {
            var existingBranches = await _context.EmployeeBranches
                .Where(eb => eb.EmployeeId == employeeId && eb.IsActive)
                .ToListAsync();

            foreach (var eb in existingBranches)
            {
                eb.IsActive = false;
                eb.UpdatedAt = DateTime.Now;
                eb.UpdatedBy = updatedBy;
            }

            foreach (var bId in branchIds)
            {
                await _context.EmployeeBranches.AddAsync(new EmployeeBranch
                {
                    EmployeeId = employeeId,
                    BranchId = bId,
                    IsActive = true,
                    CreatedAt = DateTime.Now,
                    CreatedBy = updatedBy
                });
            }
        }
    }

    public class RoleRepository : GenericRepository<RoleMaster>, IRoleRepository
    {
        public RoleRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<RoleMaster>> GetActiveRolesByCompanyIdAsync(int companyId)
        {
            return await _context.RoleMasters
                .AsNoTracking()
                .Where(r => r.CompanyId == companyId && r.IsActive)
                .ToListAsync();
        }
    }

    public class MenuRepository : GenericRepository<MenuMaster>, IMenuRepository
    {
        public MenuRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<MenuMaster>> GetMenusByRoleIdAsync(int roleId, int companyId)
        {
            return await (from m in _context.MenuMasters.AsNoTracking()
                          join rp in _context.RolePermissions.AsNoTracking() on m.MenuId equals rp.MenuId
                          where rp.RoleId == roleId
                             && rp.CanView
                             && rp.IsActive
                             && m.IsActive
                             && (m.CompanyId == null || m.CompanyId == companyId)
                          orderby m.ParentId ?? m.MenuId, m.SortOrder
                          select m).ToListAsync();
        }
        public async Task<IEnumerable<MenuMaster>> GetTenantMenusAsync(int companyId)
        {
            return await _context.MenuMasters.AsNoTracking()
                          .Where(m => m.IsActive && (m.CompanyId == null || m.CompanyId == companyId))
                          .OrderBy(m => m.ParentId ?? m.MenuId).ThenBy(m => m.SortOrder)
                          .ToListAsync();
        }
    }

    public class RolePermissionRepository : GenericRepository<RolePermission>, IRolePermissionRepository
    {
        public RolePermissionRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<RolePermission>> GetPermissionsByRoleIdAsync(int roleId)
        {
            return await _context.RolePermissions
                .AsNoTracking()
                .Where(rp => rp.RoleId == roleId && rp.IsActive)
                .ToListAsync();
        }

        public async Task<RolePermission?> GetPermissionByRoleAndMenuAsync(int roleId, int menuId)
        {
            return await _context.RolePermissions
                .AsNoTracking()
                .FirstOrDefaultAsync(rp => rp.RoleId == roleId && rp.MenuId == menuId && rp.IsActive);
        }

        public async Task UpdatePermissionsForRoleAsync(int roleId, List<(int MenuId, bool CanView, bool CanAdd, bool CanEdit, bool CanDelete, bool CanExport, bool CanPrint, bool CanApprove)> permissions, int updatedBy)
        {
            var existing = await _context.RolePermissions
                .Where(rp => rp.RoleId == roleId)
                .ToListAsync();

            foreach (var req in permissions)
            {
                var current = existing.FirstOrDefault(x => x.MenuId == req.MenuId);
                if (current != null)
                {
                    current.CanView = req.CanView;
                    current.CanAdd = req.CanAdd;
                    current.CanEdit = req.CanEdit;
                    current.CanDelete = req.CanDelete;
                    current.CanExport = req.CanExport;
                    current.CanPrint = req.CanPrint;
                    current.CanApprove = req.CanApprove;
                    current.IsActive = true;
                    current.UpdatedAt = DateTime.Now;
                    current.UpdatedBy = updatedBy;

                    _context.RolePermissions.Update(current);
                }
                else
                {
                    await _context.RolePermissions.AddAsync(new RolePermission
                    {
                        RoleId = roleId,
                        MenuId = req.MenuId,
                        CanView = req.CanView,
                        CanAdd = req.CanAdd,
                        CanEdit = req.CanEdit,
                        CanDelete = req.CanDelete,
                        CanExport = req.CanExport,
                        CanPrint = req.CanPrint,
                        CanApprove = req.CanApprove,
                        IsActive = true,
                        CreatedAt = DateTime.Now,
                        CreatedBy = updatedBy
                    });
                }
            }
        }
    }

    public class RefreshTokenRepository : GenericRepository<RefreshToken>, IRefreshTokenRepository
    {
        public RefreshTokenRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<RefreshToken?> GetByTokenAsync(string token)
        {
            return await _context.RefreshTokens
                .AsNoTracking()
                .FirstOrDefaultAsync(rt => rt.Token == token && !rt.IsRevoked && rt.IsActive);
        }

        public async Task RevokeTokensByEmployeeIdAsync(int employeeId)
        {
            var activeTokens = await _context.RefreshTokens
                .Where(rt => rt.EmployeeId == employeeId && !rt.IsRevoked)
                .ToListAsync();

            foreach (var t in activeTokens)
            {
                t.IsRevoked = true;
                t.RevokedAt = DateTime.Now;
            }

            _context.RefreshTokens.UpdateRange(activeTokens);
        }
    }

    public class LoginHistoryRepository : GenericRepository<LoginHistory>, ILoginHistoryRepository
    {
        public LoginHistoryRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task LogLoginAsync(LoginHistory history)
        {
            await AddAsync(history);
        }

        public async Task LogLogoutAsync(int employeeId)
        {
            var history = await _context.LoginHistories
                .Where(x => x.EmployeeId == employeeId && x.LogoutAt == null)
                .OrderByDescending(x => x.LoginAt)
                .FirstOrDefaultAsync();

            if (history != null)
            {
                history.LogoutAt = DateTime.Now;
                history.Status = "Logged Out";
                history.UpdatedAt = DateTime.Now;
                history.UpdatedBy = employeeId;
                _context.LoginHistories.Update(history);
            }
        }
    }

    public class EnumTypeRepository : GenericRepository<EnumMaster>, IEnumTypeRepository
    {
        public EnumTypeRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<EnumMaster>> GetEnumTypesByCategoryIdAsync(short categoryId)
        {
            return await _context.EnumMasters
                .Where(e => e.EnumCategoryId == categoryId && e.IsActive)
                .OrderBy(e => e.SortOrder)
                .ToListAsync();
        }
    }

    public class ApiKeyRepository : GenericRepository<ApiKeySetting>, IApiKeyRepository
    {
        public ApiKeyRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }
    }
}
