using CallMatrix.DAL.Data;

namespace CallMatrix.Extensions;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? EmployeeId
    {
        get
        {
            var val = _httpContextAccessor.HttpContext?.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            return string.IsNullOrEmpty(val) ? null : int.Parse(val);
        }
    }

    public int? CompanyId
    {
        get
        {
            var val = _httpContextAccessor.HttpContext?.User?.FindFirst("CompanyId")?.Value;
            return string.IsNullOrEmpty(val) ? null : int.Parse(val);
        }
    }
}
