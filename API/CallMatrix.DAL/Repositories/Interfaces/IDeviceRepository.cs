using CallMatrix.DAL.Entities;
using CallMatrix.DAL.Repositories.Generic;

namespace CallMatrix.DAL.Repositories.Interfaces
{
    public interface IDeviceRepository : IGenericRepository<UserDevice>
    {
        Task<UserDevice?> GetByDeviceIdAsync(string deviceId);
        Task<IEnumerable<UserDevice>> GetDevicesByEmployeeIdAsync(int employeeId);
        Task<IEnumerable<UserDevice>> GetDevicesByCompanyIdAsync(int companyId);
    }
}
