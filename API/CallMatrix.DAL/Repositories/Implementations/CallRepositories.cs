using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.Repositories.Generic;
using CallMatrix.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.DAL.Repositories.Implementations
{
    public class CallRepository : GenericRepository<CallMaster>, ICallRepository
    {
        public CallRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public override async Task<(IEnumerable<CallMaster> Items, int TotalCount)> GetPagedAsync(
            int page, 
            int pageSize, 
            string? search = null, 
            string? sortBy = null, 
            string? sortOrder = "ASC", 
            Dictionary<string, object>? filters = null)
        {
            var query = _context.CallMasters
                .Include(c => c.Employee)
                .AsNoTracking();

            if (filters != null && filters.TryGetValue("CompanyId", out var companyIdVal) && companyIdVal is int companyId)
            {
                query = query.Where(c => c.CompanyId == companyId);
            }

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(c => c.PhoneNumber.Contains(search) || (c.ContactName != null && c.ContactName.Contains(search)));
            }

            // Default sort by CallDateTime DESC (latest call first)
            query = query.OrderByDescending(c => c.CallDateTime);

            int totalCount = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (items, totalCount);
        }

        public async Task<IEnumerable<CallMaster>> GetCallsByEmployeeIdAsync(int employeeId)
        {
            return await _context.CallMasters
                .AsNoTracking()
                .Where(c => c.EmployeeId == employeeId && c.IsActive)
                .OrderByDescending(c => c.CallDateTime)
                .ToListAsync();
        }

        public async Task<IEnumerable<CallMaster>> GetCallsByCompanyIdAsync(int companyId)
        {
            return await _context.CallMasters
                .AsNoTracking()
                .Where(c => c.CompanyId == companyId && c.IsActive)
                .OrderByDescending(c => c.CallDateTime)
                .ToListAsync();
        }
    }

    public class CallRecordingRepository : GenericRepository<CallRecording>, ICallRecordingRepository
    {
        public CallRecordingRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
            : base(context, connectionFactory) { }

        public async Task<CallRecording?> GetByCallIdAsync(int callId)
        {
            return await _context.CallRecordings
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.CallId == callId && r.IsActive);
        }

        public async Task<IEnumerable<CallRecording>> GetRecordingsByCompanyIdAsync(int companyId)
        {
            return await _context.CallRecordings
                .AsNoTracking()
                .Where(r => r.CompanyId == companyId && r.IsActive)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();
        }
    }
}
