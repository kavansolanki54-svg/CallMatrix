using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Organization;
using Callalyze.DTO.Response.Organization;

namespace Callalyze.BLL.Interfaces
{
    public interface IOrganizationService
    {
        // Branch
        Task<ApiResponse<IEnumerable<BranchResponse>>> GetBranchesAsync(int companyId, string searchTerm = "");
        Task<ApiResponse<BranchResponse>> CreateBranchAsync(CreateBranchRequest request, int userId);
        Task<ApiResponse<BranchResponse>> UpdateBranchAsync(int id, UpdateBranchRequest request, int userId);
        Task<ApiResponse<bool>> DeleteBranchAsync(int id, int userId);

        // Department
        Task<ApiResponse<IEnumerable<DepartmentResponse>>> GetDepartmentsAsync(int companyId, string searchTerm = "");
        Task<ApiResponse<DepartmentResponse>> CreateDepartmentAsync(CreateDepartmentRequest request, int userId);
        Task<ApiResponse<DepartmentResponse>> UpdateDepartmentAsync(int id, UpdateDepartmentRequest request, int userId);
        Task<ApiResponse<bool>> DeleteDepartmentAsync(int id, int userId);

        // Designation
        Task<ApiResponse<IEnumerable<DesignationResponse>>> GetDesignationsAsync(int companyId, string searchTerm = "");
        Task<ApiResponse<DesignationResponse>> CreateDesignationAsync(CreateDesignationRequest request, int userId);
        Task<ApiResponse<DesignationResponse>> UpdateDesignationAsync(int id, UpdateDesignationRequest request, int userId);
        Task<ApiResponse<bool>> DeleteDesignationAsync(int id, int userId);
    }
}
