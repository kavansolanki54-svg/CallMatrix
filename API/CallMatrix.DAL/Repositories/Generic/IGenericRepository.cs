using System.Data;

namespace CallMatrix.DAL.Repositories.Generic
{
    public interface IGenericRepository<T> where T : class
    {
        // Write Operations (EF Core)
        Task<T?> GetByIdAsync(int id);
        Task<T> AddAsync(T entity);
        Task UpdateAsync(T entity);
        Task SoftDeleteAsync(int id, int deletedByEmployeeId);

        // Read Operations (Dapper)
        IQueryable<T> Query();
        Task<IEnumerable<T>> GetAllAsync();
        Task<(IEnumerable<T> Items, int TotalCount)> GetPagedAsync(
            int page, 
            int pageSize, 
            string? search = null, 
            string? sortBy = null, 
            string? sortOrder = "ASC", 
            Dictionary<string, object>? filters = null);
        
        Task<T?> QueryFirstOrDefaultAsync(string sql, object? param = null);
        Task<IEnumerable<T>> QueryAsync(string sql, object? param = null);
        Task<IEnumerable<TResult>> QueryAsync<TResult>(string sql, object? param = null);
    }
}
