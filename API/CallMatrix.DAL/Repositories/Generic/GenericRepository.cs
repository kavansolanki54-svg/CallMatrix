using System.Data;
using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using Dapper;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.DAL.Repositories.Generic
{
    public class GenericRepository<T> : IGenericRepository<T> where T : class
    {
        protected readonly CallMatrixDbContext _context;
        protected readonly IDbConnectionFactory _connectionFactory;
        protected readonly string _tableName;

        public GenericRepository(CallMatrixDbContext context, IDbConnectionFactory connectionFactory)
        {
            _context = context;
            _connectionFactory = connectionFactory;
            _tableName = typeof(T).Name;
        }

        #region Write Operations (EF Core)

        public async Task<T?> GetByIdAsync(int id)
        {
            return await _context.Set<T>().FindAsync(id);
        }

        public async Task<T> AddAsync(T entity)
        {
            await _context.Set<T>().AddAsync(entity);
            return entity;
        }

        public Task UpdateAsync(T entity)
        {
            _context.Set<T>().Update(entity);
            return Task.CompletedTask;
        }

        public async Task SoftDeleteAsync(int id, int deletedByEmployeeId)
        {
            var entity = await GetByIdAsync(id);
            if (entity != null)
            {
                var isActiveProp = typeof(T).GetProperty("IsActive");
                var updatedByProp = typeof(T).GetProperty("UpdatedBy");
                var updatedAtProp = typeof(T).GetProperty("UpdatedAt");

                if (isActiveProp != null && isActiveProp.CanWrite)
                    isActiveProp.SetValue(entity, false);

                if (updatedByProp != null && updatedByProp.CanWrite)
                    updatedByProp.SetValue(entity, deletedByEmployeeId);

                if (updatedAtProp != null && updatedAtProp.CanWrite)
                    updatedAtProp.SetValue(entity, DateTime.Now);

                _context.Set<T>().Update(entity);
            }
        }

        #endregion

        #region Read Operations (Dapper & EF Core)

        public IQueryable<T> Query()
        {
            return _context.Set<T>().AsNoTracking();
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _context.Set<T>()
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<(IEnumerable<T> Items, int TotalCount)> GetPagedAsync(
            int page, 
            int pageSize, 
            string? search = null, 
            string? sortBy = null, 
            string? sortOrder = "ASC", 
            Dictionary<string, object>? filters = null)
        {
            var query = _context.Set<T>().AsNoTracking();

            int totalCount = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (items, totalCount);
        }

        public async Task<T?> QueryFirstOrDefaultAsync(string spName, object? param = null)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryFirstOrDefaultAsync<T>(spName, param, commandType: CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<T>> QueryAsync(string spName, object? param = null)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<T>(spName, param, commandType: CommandType.StoredProcedure);
        }

        public async Task<IEnumerable<TResult>> QueryAsync<TResult>(string spName, object? param = null)
        {
            using var connection = _connectionFactory.CreateConnection();
            return await connection.QueryAsync<TResult>(spName, param, commandType: CommandType.StoredProcedure);
        }

        #endregion
    }
}
