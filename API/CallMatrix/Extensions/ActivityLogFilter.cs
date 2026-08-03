using Microsoft.AspNetCore.Mvc.Filters;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.Entities;

namespace CallMatrix.Extensions
{
    public class ActivityLogFilter : IAsyncActionFilter
    {
        private readonly CallMatrixDbContext _dbContext;

        public ActivityLogFilter(CallMatrixDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var resultContext = await next();

            var request = context.HttpContext.Request;
            var method = request.Method.ToUpper();

            // Only log mutating actions automatically
            if (method == "GET" || method == "OPTIONS")
                return;

            var employeeIdStr = context.HttpContext.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var companyIdStr = context.HttpContext.User?.FindFirst("CompanyId")?.Value;

            if (string.IsNullOrEmpty(employeeIdStr) || string.IsNullOrEmpty(companyIdStr))
                return; // Only log authenticated user actions

            var controllerName = context.ActionDescriptor.RouteValues["controller"] ?? "Unknown";
            var actionName = context.ActionDescriptor.RouteValues["action"] ?? "Unknown";

            var activityLog = new ActivityLog
            {
                CompanyId = int.Parse(companyIdStr),
                EmployeeId = int.Parse(employeeIdStr),
                Action = actionName,
                EntityType = controllerName,
                Description = $"Executed {method} {request.Path}",
                Ipaddress = context.HttpContext.Connection.RemoteIpAddress?.ToString(),
                UserAgent = request.Headers["User-Agent"].ToString(),
                CreatedAt = DateTime.Now,
                CreatedBy = int.Parse(employeeIdStr),
                IsActive = true
            };

            _dbContext.ActivityLogs.Add(activityLog);
            await _dbContext.SaveChangesAsync();
        }
    }
}
