using Callalyze.DAL.Entities;
using Callalyze.DAL.Repositories.Generic;

namespace Callalyze.DAL.Repositories.Interfaces
{
    public interface ILeadRepository : IGenericRepository<LeadMaster>
    {
        Task<IEnumerable<LeadMaster>> GetLeadsByCompanyIdAsync(int companyId);
        Task<IEnumerable<(string ItemType, string Title, string? Description, DateTime EventDate, string? PerformedByName)>> GetLeadTimelineAsync(int leadId);
    }

    public interface ICustomerRepository : IGenericRepository<CustomerMaster>
    {
        Task<IEnumerable<CustomerMaster>> GetCustomersByCompanyIdAsync(int companyId);
    }

    public interface IContactRepository : IGenericRepository<ContactMaster>
    {
        Task<IEnumerable<ContactMaster>> GetContactsByCustomerIdAsync(int customerId);
    }

    public interface IFollowUpRepository : IGenericRepository<FollowUp>
    {
        Task<IEnumerable<FollowUp>> GetPendingFollowUpsAsync(int assignedTo);
    }

    public interface ITaskRepository : IGenericRepository<TaskMaster>
    {
        Task<IEnumerable<TaskMaster>> GetTasksByAssignedToAsync(int assignedTo);
    }

    public interface INoteRepository : IGenericRepository<NoteMaster>
    {
        Task<IEnumerable<NoteMaster>> GetNotesByLeadIdAsync(int leadId);
    }
}
