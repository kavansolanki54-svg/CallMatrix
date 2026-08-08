using CallMatrix.DAL.Repositories.Interfaces;

namespace CallMatrix.DAL.UnitOfWork
{
    public interface IUnitOfWork : IDisposable
    {
        ICompanyRepository Companies { get; }
        IBranchRepository Branches { get; }
        IDepartmentRepository Departments { get; }
        IDesignationRepository Designations { get; }
        IEmployeeRepository Employees { get; }
        IRoleRepository Roles { get; }
        IMenuRepository Menus { get; }
        IRolePermissionRepository RolePermissions { get; }
        IRefreshTokenRepository RefreshTokens { get; }
        ILoginHistoryRepository LoginHistory { get; }
        ILeadRepository Leads { get; }
        ICustomerRepository Customers { get; }
        IContactRepository Contacts { get; }
        IFollowUpRepository FollowUps { get; }
        ITaskRepository Tasks { get; }
        INoteRepository Notes { get; }
        ICallRepository Calls { get; }
        ICallRecordingRepository CallRecordings { get; }
        IDeviceRepository Devices { get; }
        IEnumTypeRepository EnumTypes { get; }
        IApiKeyRepository ApiKeys { get; }

        Task<int> SaveChangesAsync();
        Task BeginTransactionAsync();
        Task CommitTransactionAsync();
        Task RollbackTransactionAsync();
    }
}
