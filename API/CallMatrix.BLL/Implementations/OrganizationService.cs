using CallMatrix.BLL.Interfaces;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Organization;
using CallMatrix.DTO.Response.Organization;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.BLL.Implementations
{
    public class OrganizationService : IOrganizationService
    {
        private readonly IUnitOfWork _unitOfWork;

        public OrganizationService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        #region Branch
        public async Task<ApiResponse<IEnumerable<BranchResponse>>> GetBranchesAsync(int companyId, string searchTerm = "")
        {
            try
            {
                var query = _unitOfWork.Branches.Query()
                    .Include(b => b.Company)
                    .Where(b => b.CompanyId == companyId && b.IsActive);

                if (!string.IsNullOrWhiteSpace(searchTerm))
                {
                    query = query.Where(b => b.BranchName.Contains(searchTerm) || b.BranchCode.Contains(searchTerm) || b.City.Contains(searchTerm));
                }

                var branches = await query.Select(b => new BranchResponse
                {
                    BranchId = b.BranchId,
                    CompanyId = b.CompanyId,
                    CompanyName = b.Company != null ? b.Company.CompanyName : "",
                    BranchName = b.BranchName,
                    BranchCode = b.BranchCode,
                    Address = b.Address,
                    Country = b.Country,
                    State = b.State,
                    City = b.City,
                    Pincode = b.Pincode,
                    Phone = b.Phone,
                    Email = b.Email,
                    IsActive = b.IsActive
                }).ToListAsync();

                return new ApiResponse<IEnumerable<BranchResponse>> { Success = true, Data = branches, Message = "Success" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<IEnumerable<BranchResponse>> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<BranchResponse>> CreateBranchAsync(CreateBranchRequest request, int userId)
        {
            try
            {
                var branch = new BranchMaster
                {
                    CompanyId = request.CompanyId,
                    BranchName = request.BranchName,
                    BranchCode = request.BranchCode,
                    Address = request.Address,
                    Country = request.Country,
                    State = request.State,
                    City = request.City,
                    Pincode = request.Pincode,
                    Phone = request.Phone,
                    Email = request.Email,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId,
                    Guids = Guid.NewGuid()
                };

                await _unitOfWork.Branches.AddAsync(branch);
                await _unitOfWork.SaveChangesAsync();

                var response = new BranchResponse
                {
                    BranchId = branch.BranchId,
                    CompanyId = branch.CompanyId,
                    BranchName = branch.BranchName,
                    BranchCode = branch.BranchCode,
                    Address = branch.Address,
                    Country = branch.Country,
                    State = branch.State,
                    City = branch.City,
                    Pincode = branch.Pincode,
                    Phone = branch.Phone,
                    Email = branch.Email,
                    IsActive = branch.IsActive
                };

                return new ApiResponse<BranchResponse> { Success = true, Data = response, Message = "Branch created successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<BranchResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<BranchResponse>> UpdateBranchAsync(int id, UpdateBranchRequest request, int userId)
        {
            try
            {
                var branch = await _unitOfWork.Branches.GetByIdAsync(id);
                if (branch == null || !branch.IsActive)
                    return new ApiResponse<BranchResponse> { Success = false, Message = "Branch not found" };

                branch.BranchName = request.BranchName;
                branch.BranchCode = request.BranchCode;
                branch.Address = request.Address;
                branch.Country = request.Country;
                branch.State = request.State;
                branch.City = request.City;
                branch.Pincode = request.Pincode;
                branch.Phone = request.Phone;
                branch.Email = request.Email;
                branch.UpdatedAt = DateTime.UtcNow;
                branch.UpdatedBy = userId;

                await _unitOfWork.Branches.UpdateAsync(branch);
                await _unitOfWork.SaveChangesAsync();

                var response = new BranchResponse
                {
                    BranchId = branch.BranchId,
                    CompanyId = branch.CompanyId,
                    BranchName = branch.BranchName,
                    BranchCode = branch.BranchCode,
                    Address = branch.Address,
                    Country = branch.Country,
                    State = branch.State,
                    City = branch.City,
                    Pincode = branch.Pincode,
                    Phone = branch.Phone,
                    Email = branch.Email,
                    IsActive = branch.IsActive
                };

                return new ApiResponse<BranchResponse> { Success = true, Data = response, Message = "Branch updated successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<BranchResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<bool>> DeleteBranchAsync(int id, int userId)
        {
            try
            {
                var branch = await _unitOfWork.Branches.GetByIdAsync(id);
                if (branch == null || !branch.IsActive)
                    return new ApiResponse<bool> { Success = false, Message = "Branch not found" };

                // Soft Delete
                branch.IsActive = false;
                branch.UpdatedAt = DateTime.UtcNow;
                branch.UpdatedBy = userId;

                await _unitOfWork.Branches.UpdateAsync(branch);
                await _unitOfWork.SaveChangesAsync();

                return new ApiResponse<bool> { Success = true, Data = true, Message = "Branch deleted successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<bool> { Success = false, Message = ex.Message };
            }
        }
        #endregion

        #region Department
        public async Task<ApiResponse<IEnumerable<DepartmentResponse>>> GetDepartmentsAsync(int companyId, string searchTerm = "")
        {
            try
            {
                var query = _unitOfWork.Departments.Query()
                    .Include(d => d.Company)
                    .Include(d => d.EmployeeMasters)
                    .Where(d => d.CompanyId == companyId && d.IsActive);

                if (!string.IsNullOrWhiteSpace(searchTerm))
                {
                    query = query.Where(d => d.DepartmentName.Contains(searchTerm) || d.DepartmentCode.Contains(searchTerm));
                }

                var departments = await query.Select(d => new DepartmentResponse
                {
                    DepartmentId = d.DepartmentId,
                    CompanyId = d.CompanyId,
                    CompanyName = d.Company != null ? d.Company.CompanyName : "",
                    DepartmentName = d.DepartmentName,
                    DepartmentCode = d.DepartmentCode,
                    EmployeeCount = d.EmployeeMasters.Count(e => e.IsActive), // Only count active employees
                    IsActive = d.IsActive
                }).ToListAsync();

                return new ApiResponse<IEnumerable<DepartmentResponse>> { Success = true, Data = departments, Message = "Success" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<IEnumerable<DepartmentResponse>> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<DepartmentResponse>> CreateDepartmentAsync(CreateDepartmentRequest request, int userId)
        {
            try
            {
                var department = new DepartmentMaster
                {
                    CompanyId = request.CompanyId,
                    DepartmentName = request.DepartmentName,
                    DepartmentCode = request.DepartmentCode,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId,
                    Guids = Guid.NewGuid()
                };

                await _unitOfWork.Departments.AddAsync(department);
                await _unitOfWork.SaveChangesAsync();

                var response = new DepartmentResponse
                {
                    DepartmentId = department.DepartmentId,
                    CompanyId = department.CompanyId,
                    DepartmentName = department.DepartmentName,
                    DepartmentCode = department.DepartmentCode,
                    IsActive = department.IsActive
                };

                return new ApiResponse<DepartmentResponse> { Success = true, Data = response, Message = "Department created successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<DepartmentResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<DepartmentResponse>> UpdateDepartmentAsync(int id, UpdateDepartmentRequest request, int userId)
        {
            try
            {
                var department = await _unitOfWork.Departments.GetByIdAsync(id);
                if (department == null || !department.IsActive)
                    return new ApiResponse<DepartmentResponse> { Success = false, Message = "Department not found" };

                department.DepartmentName = request.DepartmentName;
                department.DepartmentCode = request.DepartmentCode;
                department.UpdatedAt = DateTime.UtcNow;
                department.UpdatedBy = userId;

                await _unitOfWork.Departments.UpdateAsync(department);
                await _unitOfWork.SaveChangesAsync();

                var response = new DepartmentResponse
                {
                    DepartmentId = department.DepartmentId,
                    CompanyId = department.CompanyId,
                    DepartmentName = department.DepartmentName,
                    DepartmentCode = department.DepartmentCode,
                    IsActive = department.IsActive
                };

                return new ApiResponse<DepartmentResponse> { Success = true, Data = response, Message = "Department updated successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<DepartmentResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<bool>> DeleteDepartmentAsync(int id, int userId)
        {
            try
            {
                var department = await _unitOfWork.Departments.GetByIdAsync(id);
                if (department == null || !department.IsActive)
                    return new ApiResponse<bool> { Success = false, Message = "Department not found" };

                // Soft Delete
                department.IsActive = false;
                department.UpdatedAt = DateTime.UtcNow;
                department.UpdatedBy = userId;

                await _unitOfWork.Departments.UpdateAsync(department);
                await _unitOfWork.SaveChangesAsync();

                return new ApiResponse<bool> { Success = true, Data = true, Message = "Department deleted successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<bool> { Success = false, Message = ex.Message };
            }
        }
        #endregion

        #region Designation
        public async Task<ApiResponse<IEnumerable<DesignationResponse>>> GetDesignationsAsync(int companyId, string searchTerm = "")
        {
            try
            {
                var query = _unitOfWork.Designations.Query()
                    .Include(d => d.Company)
                    .Include(d => d.EmployeeMasters)
                    .Where(d => d.CompanyId == companyId && d.IsActive);

                if (!string.IsNullOrWhiteSpace(searchTerm))
                {
                    query = query.Where(d => d.DesignationName.Contains(searchTerm));
                }

                var designations = await query.Select(d => new DesignationResponse
                {
                    DesignationId = d.DesignationId,
                    CompanyId = d.CompanyId,
                    CompanyName = d.Company != null ? d.Company.CompanyName : "",
                    DepartmentId = d.DepartmentId,
                    DesignationName = d.DesignationName,
                    Description = d.Description,
                    EmployeeCount = d.EmployeeMasters.Count(e => e.IsActive),
                    IsActive = d.IsActive
                }).ToListAsync();

                return new ApiResponse<IEnumerable<DesignationResponse>> { Success = true, Data = designations, Message = "Success" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<IEnumerable<DesignationResponse>> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<DesignationResponse>> CreateDesignationAsync(CreateDesignationRequest request, int userId)
        {
            try
            {
                var designation = new DesignationMaster
                {
                    CompanyId = request.CompanyId,
                    DepartmentId = request.DepartmentId > 0 ? request.DepartmentId : 1, // Fallback if 0
                    DesignationName = request.DesignationName,
                    Description = request.Description,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId,
                    Guids = Guid.NewGuid()
                };

                await _unitOfWork.Designations.AddAsync(designation);
                await _unitOfWork.SaveChangesAsync();

                var response = new DesignationResponse
                {
                    DesignationId = designation.DesignationId,
                    CompanyId = designation.CompanyId,
                    DepartmentId = designation.DepartmentId,
                    DesignationName = designation.DesignationName,
                    Description = designation.Description,
                    IsActive = designation.IsActive
                };

                return new ApiResponse<DesignationResponse> { Success = true, Data = response, Message = "Designation created successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<DesignationResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<DesignationResponse>> UpdateDesignationAsync(int id, UpdateDesignationRequest request, int userId)
        {
            try
            {
                var designation = await _unitOfWork.Designations.GetByIdAsync(id);
                if (designation == null || !designation.IsActive)
                    return new ApiResponse<DesignationResponse> { Success = false, Message = "Designation not found" };

                designation.DesignationName = request.DesignationName;
                designation.Description = request.Description;
                if (request.DepartmentId > 0)
                    designation.DepartmentId = request.DepartmentId;
                    
                designation.UpdatedAt = DateTime.UtcNow;
                designation.UpdatedBy = userId;

                await _unitOfWork.Designations.UpdateAsync(designation);
                await _unitOfWork.SaveChangesAsync();

                var response = new DesignationResponse
                {
                    DesignationId = designation.DesignationId,
                    CompanyId = designation.CompanyId,
                    DepartmentId = designation.DepartmentId,
                    DesignationName = designation.DesignationName,
                    Description = designation.Description,
                    IsActive = designation.IsActive
                };

                return new ApiResponse<DesignationResponse> { Success = true, Data = response, Message = "Designation updated successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<DesignationResponse> { Success = false, Message = ex.Message };
            }
        }

        public async Task<ApiResponse<bool>> DeleteDesignationAsync(int id, int userId)
        {
            try
            {
                var designation = await _unitOfWork.Designations.GetByIdAsync(id);
                if (designation == null || !designation.IsActive)
                    return new ApiResponse<bool> { Success = false, Message = "Designation not found" };

                // Soft Delete
                designation.IsActive = false;
                designation.UpdatedAt = DateTime.UtcNow;
                designation.UpdatedBy = userId;

                await _unitOfWork.Designations.UpdateAsync(designation);
                await _unitOfWork.SaveChangesAsync();

                return new ApiResponse<bool> { Success = true, Data = true, Message = "Designation deleted successfully" };
            }
            catch (Exception ex)
            {
                return new ApiResponse<bool> { Success = false, Message = ex.Message };
            }
        }
        #endregion
    }
}
