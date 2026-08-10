using Callalyze.BLL.Interfaces;
using Callalyze.DAL.Entities;
using Callalyze.DAL.UnitOfWork;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Auth;
using Callalyze.DTO.Response.Auth;
using Callalyze.Utilities.Helper;

namespace Callalyze.BLL.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly JwtHelper _jwtHelper;
        private readonly Encryption _encryption;

        public AuthService(IUnitOfWork unitOfWork, JwtHelper jwtHelper, Encryption encryption)
        {
            _unitOfWork = unitOfWork;
            _jwtHelper = jwtHelper;
            _encryption = encryption;
        }

        public async Task<ApiResponse<bool>> SignUpAsync(SignUpRequest request)
        {
            var existingUser = await _unitOfWork.Employees.GetByEmailAsync(request.Email);
            if (existingUser != null)
            {
                return ApiResponse<bool>.Fail("Email is already registered", 400);
            }

            // 1. Create CompanyMaster entry for new registration
            var companyEntity = new CompanyMaster
            {
                CompanyName = string.IsNullOrWhiteSpace(request.CompanyName) ? request.FullName + " Enterprise" : request.CompanyName,
                CompanyCode = "CMP-" + Random.Shared.Next(1000, 9999),
                Email = request.Email,
                CreatedAt = DateTime.Now,
                IsActive = true
            };
            await _unitOfWork.Companies.AddAsync(companyEntity);
            await _unitOfWork.SaveChangesAsync();

            // 2. Create Tenant Owner in EmployeeMaster (Tenant = true)
            string hashedPassword = _encryption.HashPassword(request.Email, request.Password);
            var employeeEntity = new EmployeeMaster
            {
                Tenant = true, // Set Tenant = true (1) for Company Owner
                CompanyId = companyEntity.CompanyId,
                DepartmentId = 1,
                DesignationId = 1,
                RoleId = request.RoleId,
                EmployeeCode = "EMP-OWNER",
                FirstName = request.FullName.Split(' ')[0],
                LastName = request.FullName.Contains(" ") ? request.FullName.Substring(request.FullName.IndexOf(' ') + 1) : "Owner",
                EmployeeName = request.FullName,
                Email = request.Email,
                Phone = "+1-555-0199",
                Password = hashedPassword,
                CreatedAt = DateTime.Now,
                IsActive = true
            };

            await _unitOfWork.Employees.AddAsync(employeeEntity);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Signup successful", 201);
        }

        public async Task<ApiResponse<LoginResponse>> LoginAsync(LoginRequest request, string ipAddress = "Unknown", string userAgent = "Unknown")
        {
            var user = await _unitOfWork.Employees.GetByEmailAsync(request.Email);
            if (user == null)
            {
                return ApiResponse<LoginResponse>.Fail("User not found", 404);
            }

            // Password Verification: Supports identity PBKDF2 hash, legacy fallback, or demo pass
            bool isPasswordCorrect = false;
            if (!string.IsNullOrEmpty(user.Password) && user.Password.StartsWith("AQAAAA"))
            {
                isPasswordCorrect = _encryption.VerifyPassword(request.Email, user.Password, request.Password);
            }
            else
            {
                isPasswordCorrect = user.Password == request.Password || request.Password == "123456" || request.Password == "Admin@123";
            }

            if (!isPasswordCorrect)
            {
                return ApiResponse<LoginResponse>.Fail("username and password is invalid", 401);
            }

            var role = user.RoleId.HasValue ? await _unitOfWork.Roles.GetByIdAsync(user.RoleId.Value) : null;
            string roleName = role?.RoleName ?? "Company Admin";

            var (accessToken, expiresAt) = _jwtHelper.GenerateAccessToken(user, roleName);
            var refreshTokenValue = _jwtHelper.GenerateRefreshToken();

            var refreshTokenEntity = new RefreshToken
            {
                CompanyId = user.CompanyId,
                EmployeeId = user.EmployeeId,
                Token = refreshTokenValue,
                ExpiresAt = DateTime.Now.AddDays(7),
                CreatedAt = DateTime.Now,
                IsActive = true
            };

            await _unitOfWork.RefreshTokens.AddAsync(refreshTokenEntity);

            var loginHistory = new LoginHistory
            {
                CompanyId = user.CompanyId,
                EmployeeId = user.EmployeeId,
                LoginAt = DateTime.Now,
                Status = "Success",
                Ipaddress = ipAddress, 
                UserAgent = userAgent, 
                DeviceInfo = request.DeviceInfo,
                CreatedBy = user.EmployeeId,
                CreatedAt = DateTime.Now,
                IsActive = true
            };
            await _unitOfWork.LoginHistory.LogLoginAsync(loginHistory);

            await _unitOfWork.SaveChangesAsync();

            var response = new LoginResponse
            {
                Token = accessToken,
                RefreshToken = refreshTokenValue,
                ExpiresAt = expiresAt,
                User = new UserInfoDto
                {
                    EmployeeId = user.EmployeeId,
                    CompanyId = user.CompanyId,
                    RoleId = user.RoleId ?? 0,
                    RoleName = roleName,
                    EmployeeName = user.EmployeeName,
                    Email = user.Email,
                    Tenant = user.Tenant
                }
            };

            return ApiResponse<LoginResponse>.Ok(response, "Login successful");
        }

        public async Task<ApiResponse<LoginResponse>> RefreshTokenAsync(RefreshTokenRequest request)
        {
            var tokenEntity = await _unitOfWork.RefreshTokens.GetByTokenAsync(request.Token);
            if (tokenEntity == null || !tokenEntity.IsActive || tokenEntity.ExpiresAt <= DateTime.Now)
            {
                return ApiResponse<LoginResponse>.Fail("Invalid or expired refresh token", 401);
            }

            var user = await _unitOfWork.Employees.GetByIdAsync(tokenEntity.EmployeeId);
            if (user == null || !user.IsActive)
            {
                return ApiResponse<LoginResponse>.Fail("User not found or inactive", 401);
            }

            var role = user.RoleId.HasValue ? await _unitOfWork.Roles.GetByIdAsync(user.RoleId.Value) : null;
            string roleName = role?.RoleName ?? "Employee";

            var (newAccessToken, expiresAt) = _jwtHelper.GenerateAccessToken(user, roleName);
            var newRefreshTokenValue = _jwtHelper.GenerateRefreshToken();

            tokenEntity.IsActive = false;
            await _unitOfWork.RefreshTokens.UpdateAsync(tokenEntity);

            await _unitOfWork.RefreshTokens.AddAsync(new RefreshToken
            {
                CompanyId = user.CompanyId,
                EmployeeId = user.EmployeeId,
                Token = newRefreshTokenValue,
                ExpiresAt = DateTime.Now.AddDays(7),
                CreatedAt = DateTime.Now,
                IsActive = true
            });

            await _unitOfWork.SaveChangesAsync();

            var response = new LoginResponse
            {
                Token = newAccessToken,
                RefreshToken = newRefreshTokenValue,
                ExpiresAt = expiresAt,
                User = new UserInfoDto
                {
                    EmployeeId = user.EmployeeId,
                    CompanyId = user.CompanyId,
                    RoleId = user.RoleId ?? 0,
                    RoleName = roleName,
                    EmployeeName = user.EmployeeName,
                    Email = user.Email,
                    Tenant = user.Tenant
                }
            };

            return ApiResponse<LoginResponse>.Ok(response, "Token refreshed successfully");
        }

        public async Task<ApiResponse<bool>> LogoutAsync(int employeeId)
        {
            await _unitOfWork.RefreshTokens.RevokeTokensByEmployeeIdAsync(employeeId);
            await _unitOfWork.LoginHistory.LogLogoutAsync(employeeId);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<bool>.Ok(true, "Logged out successfully");
        }
    }
}
