using CallMatrix.Extensions;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// 1. Serilog Setup
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("Logs/CallMatrix-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// 2. Application Service Registration via Extension
builder.Services.AddApplicationServices(builder.Configuration);

// 3. Controllers
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ActivityLogFilter>();
});
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

// 4. Middleware Pipeline
app.UseCustomExceptionMiddleware();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "CallMatrix API v1");
    c.RoutePrefix = string.Empty; // serves Swagger UI at the application's root
});

app.UseSerilogRequestLogging();
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();
app.UseStaticFiles();

app.MapControllers();

app.Run();
