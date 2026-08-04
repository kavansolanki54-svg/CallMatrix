using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Auth;
using CallMatrix.DTO.Request.Calls;
using CallMatrix.DTO.Request.CRM;
using CallMatrix.DTO.Request.Device;
using CallMatrix.DTO.Request.Employee;
using CallMatrix.DTO.Request.Role;
using CallMatrix.DTO.Response.Auth;
using CallMatrix.DTO.Response.Calls;
using CallMatrix.DTO.Response.CRM;
using CallMatrix.DTO.Response.Device;
using CallMatrix.DTO.Response.Employee;
using CallMatrix.DTO.Response.Menu;
using CallMatrix.DTO.Response.Role;

namespace CallMatrix.BLL.Interfaces
{
    public interface IAuthService
    {
        Task<ApiResponse<LoginResponse>> LoginAsync(LoginRequest request, string ipAddress = "Unknown", string userAgent = "Unknown");
        Task<ApiResponse<bool>> SignUpAsync(SignUpRequest request);
        Task<ApiResponse<LoginResponse>> RefreshTokenAsync(RefreshTokenRequest request);
        Task<ApiResponse<bool>> LogoutAsync(int employeeId);
    }

    public interface IMenuService
    {
        Task<ApiResponse<List<MenuTreeResponse>>> GetMenuTreeByRoleIdAsync(int roleId, int companyId, bool isTenant = false);
        Task<ApiResponse<IEnumerable<MenuResponse>>> GetAllMenusAsync(int companyId);
        Task<ApiResponse<MenuResponse>> CreateMenuAsync(DTO.Request.Menu.CreateMenuRequest request, int createdBy);
        Task<ApiResponse<MenuResponse>> UpdateMenuAsync(DTO.Request.Menu.UpdateMenuRequest request, int updatedBy);
        Task<ApiResponse<bool>> DeleteMenuAsync(int menuId, int deletedBy);
    }

    public interface ILeadService
    {
        Task<ApiResponse<PaginatedResponse<LeadResponse>>> GetLeadsAsync(PaginationRequest request, int companyId);
        Task<ApiResponse<LeadResponse>> CreateLeadAsync(CreateLeadRequest request, int employeeId);
        Task<ApiResponse<bool>> UpdateLeadStatusAsync(UpdateLeadStatusRequest request, int employeeId);
        Task<ApiResponse<bool>> AssignLeadAsync(AssignLeadRequest request, int employeeId);
        Task<ApiResponse<CustomerResponse>> ConvertLeadToCustomerAsync(int leadId, int employeeId);
        Task<ApiResponse<List<TimelineItemResponse>>> GetLeadTimelineAsync(int leadId);
    }

    public interface ICustomerService
    {
        Task<ApiResponse<PaginatedResponse<CustomerResponse>>> GetCustomersAsync(PaginationRequest request, int companyId);
        Task<ApiResponse<CustomerResponse>> CreateCustomerAsync(CreateCustomerRequest request, int employeeId);
    }

    public interface ICallService
    {
        Task<ApiResponse<PaginatedResponse<CallLogResponse>>> GetCallsAsync(PaginationRequest request, int companyId);
        Task<ApiResponse<CallLogResponse>> CreateCallLogAsync(CreateCallLogRequest request, int employeeId);
        Task<ApiResponse<bool>> SyncCallsAsync(SyncCallsRequest request, int employeeId);
        Task<ApiResponse<CallRecordingResponse>> SaveCallRecordingAsync(UploadCallRecordingRequest request, System.IO.Stream? fileStream, string? fileExtension, int employeeId);
        Task<ApiResponse<CallAnalyticsSummaryResponse>> GetAnalyticsSummaryAsync(int companyId, DateTime? startDate, DateTime? endDate);
    }

    public interface IDeviceService
    {
        Task<ApiResponse<PaginatedResponse<DeviceResponse>>> GetDevicesAsync(PaginationRequest request, int companyId);
        Task<ApiResponse<DeviceResponse>> RegisterDeviceAsync(RegisterDeviceRequest request, int employeeId);
        Task<ApiResponse<bool>> UpdatePingAsync(UpdateDevicePingRequest request, int employeeId);
        Task<ApiResponse<bool>> ApproveDeviceAsync(ApproveDeviceRequest request, int employeeId);
        Task<ApiResponse<bool>> BlockDeviceAsync(BlockDeviceRequest request, int employeeId);
    }

    public interface IEmployeeService
    {
        Task<ApiResponse<PaginatedResponse<EmployeeDetailResponse>>> GetEmployeesAsync(PaginationRequest request, int companyId);
        Task<ApiResponse<EmployeeDetailResponse>> GetEmployeeByIdAsync(int employeeId);
        Task<ApiResponse<EmployeeDetailResponse>> CreateEmployeeAsync(CreateEmployeeRequest request, int createdBy);
        Task<ApiResponse<EmployeeDetailResponse>> UpdateEmployeeAsync(UpdateEmployeeRequest request, int updatedBy);
        Task<ApiResponse<bool>> DeleteEmployeeAsync(int employeeId, int deletedBy);
        Task<ApiResponse<bool>> AssignBranchesAsync(AssignEmployeeBranchesRequest request, int updatedBy);
    }

    public interface IRoleService
    {
        Task<ApiResponse<IEnumerable<RoleResponse>>> GetActiveRolesAsync(int companyId);
        Task<ApiResponse<RoleResponse>> CreateRoleAsync(CreateRoleRequest request, int createdBy);
        Task<ApiResponse<RoleResponse>> UpdateRoleAsync(UpdateRoleRequest request, int updatedBy);
        Task<ApiResponse<bool>> DeleteRoleAsync(int roleId, int deletedBy);
        Task<ApiResponse<RolePermissionMatrixResponse>> GetRolePermissionMatrixAsync(int roleId, int companyId);
        Task<ApiResponse<bool>> UpdateRolePermissionsAsync(UpdateRolePermissionsRequest request, int updatedBy);
    }
    public interface IEnumService
    {
        Task<ApiResponse<IEnumerable<CallMatrix.DTO.Response.Enum.EnumResponse>>> GetEnumValuesAsync(short categoryId);
    }
}
