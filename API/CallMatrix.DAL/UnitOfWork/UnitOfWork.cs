using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.Repositories.Implementations;
using CallMatrix.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore.Storage;

namespace CallMatrix.DAL.UnitOfWork
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly CallMatrixDbContext _context;
        private readonly IDbConnectionFactory _connectionFactory;
        private IDbContextTransaction? _transaction;

        private ICompanyRepository? _companies;
        private IBranchRepository? _branches;
        private IDepartmentRepository? _departments;
        private IDesignationRepository? _designations;
        private IEmployeeRepository? _employees;
        private IRoleRepository? _roles;
        private IMenuRepository? _menus;
        private IRolePermissionRepository? _rolePermissions;
        private IRefreshTokenRepository? _refreshTokens;
        private ILoginHistoryRepository? _loginHistory;
        private ILeadRepository? _leads;
        private ICustomerRepository? _customers;
        private IContactRepository? _contacts;
        private IFollowUpRepository? _followUps;
        private ITaskRepository? _tasks;
        private INoteRepository? _notes;
        private ICallRepository? _calls;
        private ICallRecordingRepository? _callRecordings;
        private IDeviceRepository? _devices;
        private IEnumTypeRepository? _enumTypes;

        public UnitOfWork(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
        {
            _context = context;
            _connectionFactory = connectionFactory;
        }

        public ICompanyRepository Companies => _companies ??= new CompanyRepository(_context, _connectionFactory);
        public IBranchRepository Branches => _branches ??= new BranchRepository(_context, _connectionFactory);
        public IDepartmentRepository Departments => _departments ??= new DepartmentRepository(_context, _connectionFactory);
        public IDesignationRepository Designations => _designations ??= new DesignationRepository(_context, _connectionFactory);
        public IEmployeeRepository Employees => _employees ??= new EmployeeRepository(_context, _connectionFactory);
        public IRoleRepository Roles => _roles ??= new RoleRepository(_context, _connectionFactory);
        public IMenuRepository Menus => _menus ??= new MenuRepository(_context, _connectionFactory);
        public IRolePermissionRepository RolePermissions => _rolePermissions ??= new RolePermissionRepository(_context, _connectionFactory);
        public IRefreshTokenRepository RefreshTokens => _refreshTokens ??= new RefreshTokenRepository(_context, _connectionFactory);
        public ILoginHistoryRepository LoginHistory => _loginHistory ??= new LoginHistoryRepository(_context, _connectionFactory);
        public ILeadRepository Leads => _leads ??= new LeadRepository(_context, _connectionFactory);
        public ICustomerRepository Customers => _customers ??= new CustomerRepository(_context, _connectionFactory);
        public IContactRepository Contacts => _contacts ??= new ContactRepository(_context, _connectionFactory);
        public IFollowUpRepository FollowUps => _followUps ??= new FollowUpRepository(_context, _connectionFactory);
        public ITaskRepository Tasks => _tasks ??= new TaskRepository(_context, _connectionFactory);
        public INoteRepository Notes => _notes ??= new NoteRepository(_context, _connectionFactory);
        public ICallRepository Calls => _calls ??= new CallRepository(_context, _connectionFactory);
        public ICallRecordingRepository CallRecordings => _callRecordings ??= new CallRecordingRepository(_context, _connectionFactory);
        public IDeviceRepository Devices => _devices ??= new DeviceRepository(_context, _connectionFactory);
        public IEnumTypeRepository EnumTypes => _enumTypes ??= new EnumTypeRepository(_context, _connectionFactory);

        public async Task<int> SaveChangesAsync()
        {
            return await _context.SaveChangesAsync();
        }

        public async Task BeginTransactionAsync()
        {
            _transaction = await _context.Database.BeginTransactionAsync();
        }

        public async Task CommitTransactionAsync()
        {
            if (_transaction != null)
            {
                await _transaction.CommitAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public async Task RollbackTransactionAsync()
        {
            if (_transaction != null)
            {
                await _transaction.RollbackAsync();
                await _transaction.DisposeAsync();
                _transaction = null;
            }
        }

        public void Dispose()
        {
            _transaction?.Dispose();
            _context.Dispose();
        }
    }
}
