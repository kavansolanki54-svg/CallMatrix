using Callalyze.DAL.Connection;
using Callalyze.DAL.Data;
using Callalyze.DAL.Entities;
using Callalyze.DAL.Repositories.Generic;
using Callalyze.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Callalyze.DAL.Repositories.Implementations
{
    public class DeviceRepository : GenericRepository<UserDevice>, IDeviceRepository
    {
        public DeviceRepository(CallalyzeDbContext context, IDbConnectionFactory connectionFactory)
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
