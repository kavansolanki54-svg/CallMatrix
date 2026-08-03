using System.Data;
using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.Repositories.Generic;
using CallMatrix.DAL.Repositories.Interfaces;
using Dapper;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.DAL.Repositories.Implementations
{
    public class LeadRepository : GenericRepository<LeadMaster>, ILeadRepository
    {
        public LeadRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<LeadMaster>> GetLeadsByCompanyIdAsync(int companyId)
        {
            // EF Core LINQ Query
            return await _context.LeadMasters
                .AsNoTracking()
                .Where(l => l.CompanyId == companyId && l.IsActive)
                .OrderByDescending(l => l.CreatedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<(string ItemType, string Title, string? Description, DateTime EventDate, string? PerformedByName)>> GetLeadTimelineAsync(int leadId)
        {
            var followUps = await (from f in _context.FollowUps.AsNoTracking()
                                   join e in _context.EmployeeMasters.AsNoTracking() on f.AssignedTo equals e.EmployeeId into empJoin
                                   from emp in empJoin.DefaultIfEmpty()
                                   where f.LeadId == leadId && f.IsActive
                                   select new
                                   {
                                       ItemType = "FollowUp",
                                       Title = "Follow-up Scheduled: " + (f.Notes ?? ""),
                                       Description = f.Notes,
                                       EventDate = f.ScheduledDate,
                                       PerformedByName = emp != null ? emp.EmployeeName : null
                                   }).ToListAsync();

            var notes = await (from n in _context.NoteMasters.AsNoTracking()
                               join e in _context.EmployeeMasters.AsNoTracking() on n.CreatedBy equals e.EmployeeId into empJoin
                               from emp in empJoin.DefaultIfEmpty()
                               where n.LeadId == leadId && n.IsActive
                               select new
                               {
                                   ItemType = "Note",
                                   Title = "Note Added",
                                   Description = n.Content,
                                   EventDate = n.CreatedAt,
                                   PerformedByName = emp != null ? emp.EmployeeName : null
                               }).ToListAsync();

            var tasks = await (from t in _context.TaskMasters.AsNoTracking()
                               join e in _context.EmployeeMasters.AsNoTracking() on t.AssignedTo equals e.EmployeeId into empJoin
                               from emp in empJoin.DefaultIfEmpty()
                               where t.LeadId == leadId && t.IsActive
                               select new
                               {
                                   ItemType = "Task",
                                   Title = "Task: " + t.Title,
                                   Description = t.Description,
                                   EventDate = t.CreatedAt,
                                   PerformedByName = emp != null ? emp.EmployeeName : null
                               }).ToListAsync();

            var combined = followUps.Concat(notes).Concat(tasks)
                .OrderByDescending(x => x.EventDate)
                .Select(x => (x.ItemType, x.Title, (string?)x.Description, x.EventDate, (string?)x.PerformedByName));

            return combined;
        }
    }

    public class CustomerRepository : GenericRepository<CustomerMaster>, ICustomerRepository
    {
        public CustomerRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<CustomerMaster>> GetCustomersByCompanyIdAsync(int companyId)
        {
            // EF Core LINQ Query
            return await _context.CustomerMasters
                .AsNoTracking()
                .Where(c => c.CompanyId == companyId && c.IsActive)
                .OrderByDescending(c => c.CreatedAt)
                .ToListAsync();
        }
    }

    public class ContactRepository : GenericRepository<ContactMaster>, IContactRepository
    {
        public ContactRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<ContactMaster>> GetContactsByCustomerIdAsync(int customerId)
        {
            // EF Core LINQ Query
            return await _context.ContactMasters
                .AsNoTracking()
                .Where(c => c.CustomerId == customerId && c.IsActive)
                .ToListAsync();
        }
    }

    public class FollowUpRepository : GenericRepository<FollowUp>, IFollowUpRepository
    {
        public FollowUpRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<FollowUp>> GetPendingFollowUpsAsync(int assignedTo)
        {
            // EF Core LINQ Query
            return await _context.FollowUps
                .AsNoTracking()
                .Where(f => f.AssignedTo == assignedTo && f.Status == "Pending" && f.IsActive)
                .OrderBy(f => f.ScheduledDate)
                .ToListAsync();
        }
    }

    public class TaskRepository : GenericRepository<TaskMaster>, ITaskRepository
    {
        public TaskRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<TaskMaster>> GetTasksByAssignedToAsync(int assignedTo)
        {
            // EF Core LINQ Query
            return await _context.TaskMasters
                .AsNoTracking()
                .Where(t => t.AssignedTo == assignedTo && t.IsActive)
                .OrderBy(t => t.DueDate)
                .ToListAsync();
        }
    }

    public class NoteRepository : GenericRepository<NoteMaster>, INoteRepository
    {
        public NoteRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<IEnumerable<NoteMaster>> GetNotesByLeadIdAsync(int leadId)
        {
            // EF Core LINQ Query
            return await _context.NoteMasters
                .AsNoTracking()
                .Where(n => n.LeadId == leadId && n.IsActive)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();
        }
    }
}
