using Callalyze.DAL.Entities;
using Callalyze.DAL.Repositories.Generic;

namespace Callalyze.DAL.Repositories.Interfaces
{
    public interface ICallRepository : IGenericRepository<CallMaster>
    {
        Task<IEnumerable<CallMaster>> GetCallsByEmployeeIdAsync(int employeeId);
        Task<IEnumerable<CallMaster>> GetCallsByCompanyIdAsync(int companyId);
    }

    public interface ICallRecordingRepository : IGenericRepository<CallRecording>
    {
        Task<CallRecording?> GetByCallIdAsync(int callId);
        Task<IEnumerable<CallRecording>> GetRecordingsByCompanyIdAsync(int companyId);
    }
}
