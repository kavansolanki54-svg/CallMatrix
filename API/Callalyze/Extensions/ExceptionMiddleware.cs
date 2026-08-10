using System.Net;
using System.Text.Json;
using Callalyze.DTO.Common;

namespace Callalyze.Extensions
{
    public class ExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionMiddleware> _logger;

        public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context, Callalyze.DAL.Data.CallalyzeDbContext dbContext)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An unhandled exception occurred: {Message}", ex.Message);
                await LogErrorToDatabaseAsync(context, dbContext, ex);
                await HandleExceptionAsync(context, ex);
            }
        }

        private async Task LogErrorToDatabaseAsync(HttpContext context, Callalyze.DAL.Data.CallalyzeDbContext dbContext, Exception exception)
        {
            try
            {
                var employeeIdStr = context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var companyIdStr = context.User?.FindFirst("CompanyId")?.Value;

                var errorLog = new Callalyze.DAL.Entities.ErrorLog
                {
                    EmployeeId = string.IsNullOrEmpty(employeeIdStr) ? null : int.Parse(employeeIdStr),
                    CompanyId = string.IsNullOrEmpty(companyIdStr) ? null : int.Parse(companyIdStr),
                    ErrorMessage = exception.Message,
                    StackTrace = exception.StackTrace,
                    Path = context.Request.Path,
                    Method = context.Request.Method,
                    QueryString = context.Request.QueryString.ToString(),
                    Ipaddress = context.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = context.Request.Headers["User-Agent"].ToString(),
                    CreatedAt = DateTime.Now,
                    IsActive = true
                };

                dbContext.ErrorLogs.Add(errorLog);
                await dbContext.SaveChangesAsync();
            }
            catch (Exception logEx)
            {
                _logger.LogError(logEx, "Failed to log error to database");
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            context.Response.ContentType = "application/json";
            
            var statusCode = exception switch
            {
                KeyNotFoundException => HttpStatusCode.NotFound,
                UnauthorizedAccessException => HttpStatusCode.Unauthorized,
                ArgumentException => HttpStatusCode.BadRequest,
                InvalidOperationException => HttpStatusCode.BadRequest,
                _ => HttpStatusCode.InternalServerError
            };

            context.Response.StatusCode = (int)statusCode;

            var errorsList = new List<string>();
            if (exception.InnerException != null && !string.IsNullOrEmpty(exception.InnerException.Message))
            {
                errorsList.Add(exception.InnerException.Message);
            }
            else if (!string.IsNullOrEmpty(exception.Message))
            {
                errorsList.Add(exception.Message);
            }

            var response = ApiResponse<object>.Fail(
                message: exception.Message ?? "An unexpected error occurred",
                statusCode: (int)statusCode,
                errors: errorsList
            );

            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            var json = JsonSerializer.Serialize(response, options);

            return context.Response.WriteAsync(json);
        }
    }

    public static class ExceptionMiddlewareExtensions
    {
        public static IApplicationBuilder UseCustomExceptionMiddleware(this IApplicationBuilder app)
        {
            return app.UseMiddleware<ExceptionMiddleware>();
        }
    }
}
