using Callalyze.DAL.Entities;
using Callalyze.DAL.Repositories.Generic;

namespace Callalyze.DAL.Repositories.Interfaces
{
    public interface IDeviceRepository : IGenericRepository<UserDevice>
    {
        Task<UserDevice?> GetByDeviceIdAsync(string deviceId);
        Task<IEnumerable<UserDevice>> GetDevicesByEmployeeIdAsync(int employeeId);
        Task<IEnumerable<UserDevice>> GetDevicesByCompanyIdAsync(int companyId);
    }
}
