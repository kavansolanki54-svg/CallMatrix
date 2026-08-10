namespace Callalyze.DTO.Request.Auth
{
    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? DeviceInfo { get; set; }
        public string? UserAgent { get; set; }
    }

    public class RefreshTokenRequest
    {
        public string Token { get; set; } = string.Empty;
    }

    public class SignUpRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public int? RoleId { get; set; }
    }
}
