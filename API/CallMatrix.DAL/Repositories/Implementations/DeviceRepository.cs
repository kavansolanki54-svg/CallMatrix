using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.Repositories.Generic;
using CallMatrix.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.DAL.Repositories.Implementations
{
    public class DeviceRepository : GenericRepository<UserDevice>, IDeviceRepository
    {
        public DeviceRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<UserDevice?> GetByDeviceIdAsync(string deviceId)
        {
            return await _context.UserDevices
                .AsNoTracking()
                .FirstOrDefaultAsync(d => d.DeviceId == deviceId && d.IsActive);
        }

        public async Task<IEnumerable<UserDevice>> GetDevicesByEmployeeIdAsync(int employeeId)
        {
            return await _context.UserDevices
                .AsNoTracking()
                .Where(d => d.EmployeeId == employeeId && d.IsActive)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserDevice>> GetDevicesByCompanyIdAsync(int companyId)
        {
            return await _context.UserDevices
                .AsNoTracking()
                .Where(d => d.CompanyId == companyId && d.IsActive)
                .OrderByDescending(d => d.LastSyncAt)
                .ToListAsync();
        }
    }
}
