using System.Text;
using CallMatrix.BLL.Interfaces;
using CallMatrix.BLL.Services;
using CallMatrix.BLL.Implementations;
using CallMatrix.DAL.Connection;
using CallMatrix.DAL.Data;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Mappings;
using CallMatrix.Utilities.Helper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

namespace CallMatrix.Extensions
{
    public static class ServiceRegistration
    {
        public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration configuration)
        {
            // 1. Database Context & Connection Factory
            var connectionString = configuration.GetConnectionString("DefaultConnection");
            services.AddDbContext<CallMatrixDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddSingleton<IDbConnectionFactory, DbConnectionFactory>();

            // 2. Unit of Work
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            // 3. Application Services
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IMenuService, MenuService>();
            services.AddScoped<ILeadService, LeadService>();
            services.AddScoped<ICustomerService, CustomerService>();
            services.AddScoped<ICallService, CallService>();
            services.AddScoped<IDeviceService, DeviceService>();
            services.AddScoped<IEmployeeService, EmployeeService>();
            services.AddScoped<IRoleService, RoleService>();
            services.AddScoped<IEnumService, EnumService>();
            services.AddScoped<IOrganizationService, OrganizationService>();

            // 4. AutoMapper Registration
            services.AddAutoMapper(cfg => {}, typeof(AutoMapperProfiles));

            // 5. Cross-cutting Helpers
            services.AddHttpContextAccessor();
            services.AddScoped<CallMatrix.DAL.Data.ICurrentUserService, CurrentUserService>();
            services.AddSingleton<JwtHelper>();
            services.AddSingleton<Encryption>();

            // 6. JWT Authentication
            var jwtSecretKey = configuration["JwtSettings:SecretKey"] ?? "CallMatrixSuperSecretKey2026!EnterpriseSecureJwtToken";
            var jwtIssuer = configuration["JwtSettings:Issuer"] ?? "CallMatrix";
            var jwtAudience = configuration["JwtSettings:Audience"] ?? "CallMatrixApp";

            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtIssuer,
                    ValidAudience = jwtAudience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey))
                };
            });

            services.AddAuthorization();

            // 7. CORS Policy
            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });
            });

            // 8. Swagger Documentation
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "CallMatrix ERP + CRM API", Version = "v1" });
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
                    Name = "Authorization",
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey,
                    Scheme = "Bearer"
                });
                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            return services;
        }
    }
}
