using AutoMapper;
using Callalyze.BLL.Interfaces;
using Callalyze.DAL.Entities;
using Callalyze.DAL.UnitOfWork;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.Employee;
using Callalyze.DTO.Response.Employee;
using Callalyze.Utilities.Helper;

namespace Callalyze.BLL.Services
{
    public class EmployeeService : IEmployeeService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public EmployeeService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<PaginatedResponse<EmployeeDetailResponse>>> GetEmployeesAsync(PaginationRequest request, int companyId)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;

            var (items, totalCount) = await _unitOfWork.Employees.GetPagedAsync(
                request.Page,
                request.PageSize,
                request.Search,
                request.SortBy ?? "EmployeeId",
                request.SortOrder ?? "ASC",
                filters);

            var dtos = new List<EmployeeDetailResponse>();
            foreach (var emp in items)
            {
                var dto = _mapper.Map<EmployeeDetailResponse>(emp);
                var branchIds = await _unitOfWork.Employees.GetAssignedBranchIdsAsync(emp.EmployeeId);
                dto.AssignedBranchIds = branchIds.ToList();
                dtos.Add(dto);
            }

            var result = new PaginatedResponse<EmployeeDetailResponse>(dtos, totalCount, request.Page, request.PageSize);
            return ApiResponse<PaginatedResponse<EmployeeDetailResponse>>.Ok(result, "Employees retrieved successfully");
        }

        public async Task<ApiResponse<EmployeeDetailResponse>> GetEmployeeByIdAsync(int employeeId)
        {
            var emp = await _unitOfWork.Employees.GetByIdAsync(employeeId);
            if (emp == null || !emp.IsActive)
            {
                return ApiResponse<EmployeeDetailResponse>.Fail("Employee not found", 404);
            }

            var dto = _mapper.Map<EmployeeDetailResponse>(emp);
            var branchIds = await _unitOfWork.Employees.GetAssignedBranchIdsAsync(emp.EmployeeId);
            dto.AssignedBranchIds = branchIds.ToList();

            return ApiResponse<EmployeeDetailResponse>.Ok(dto, "Employee details retrieved");
        }

        public async Task<ApiResponse<EmployeeDetailResponse>> CreateEmployeeAsync(CreateEmployeeRequest request, int createdBy)
        {
            var existingByEmail = await _unitOfWork.Employees.GetByEmailAsync(request.Email);
            if (existingByEmail != null)
            {
                return ApiResponse<EmployeeDetailResponse>.Fail("Email already exists", 400);
            }

            var existingByCode = await _unitOfWork.Employees.GetByEmployeeCodeAsync(request.EmployeeCode);
            if (existingByCode != null)
            {
                return ApiResponse<EmployeeDetailResponse>.Fail("Employee Code already exists", 400);
            }

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var entity = _mapper.Map<EmployeeMaster>(request);
                var encryptionHelper = new Encryption();
                entity.Password = encryptionHelper.HashPassword(request.Email, request.Password);
                entity.Phone = request.MobileNo;
                entity.Tenant = false; // Sub User
                entity.CreatedAt = DateTime.Now;
                entity.CreatedBy = createdBy;
                entity.IsActive = true;

                await _unitOfWork.Employees.AddAsync(entity);
                await _unitOfWork.SaveChangesAsync();

                if (request.BranchIds.Any())
                {
                    await _unitOfWork.Employees.UpdateEmployeeBranchesAsync(entity.EmployeeId, request.BranchIds, createdBy);
                    await _unitOfWork.SaveChangesAsync();
                }

                await _unitOfWork.CommitTransactionAsync();

                var dto = _mapper.Map<EmployeeDetailResponse>(entity);
                dto.AssignedBranchIds = request.BranchIds;
                return ApiResponse<EmployeeDetailResponse>.Ok(dto, "Employee created successfully", 201);
            }
            catch
            {
                await _unitOfWork.RollbackTransactionAsync();
                throw;
            }
        }

        public async Task<ApiResponse<EmployeeDetailResponse>> UpdateEmployeeAsync(UpdateEmployeeRequest request, int updatedBy)
        {
            var emp = await _unitOfWork.Employees.GetByIdAsync(request.EmployeeId);
            if (emp == null || !emp.IsActive)
            {
                return ApiResponse<EmployeeDetailResponse>.Fail("Employee not found", 404);
            }

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                emp.FirstName = request.FirstName;
                emp.MiddleName = request.MiddleName;
                emp.LastName = request.LastName;
                emp.Email = request.Email;
                emp.Phone = request.MobileNo;
                emp.RoleId = request.RoleId;
                emp.DepartmentId = request.DepartmentId;
                emp.DesignationId = request.DesignationId;
                emp.UpdatedAt = DateTime.Now;
                emp.UpdatedBy = updatedBy;

                await _unitOfWork.Employees.UpdateAsync(emp);
                await _unitOfWork.Employees.UpdateEmployeeBranchesAsync(emp.EmployeeId, request.BranchIds, updatedBy);
                await _unitOfWork.SaveChangesAsync();

                await _unitOfWork.CommitTransactionAsync();

                var dto = _mapper.Map<EmployeeDetailResponse>(emp);
                dto.AssignedBranchIds = request.BranchIds;

                return ApiResponse<EmployeeDetailResponse>.Ok(dto, "Employee updated successfully");
            }
            catch
            {
                await _unitOfWork.RollbackTransactionAsync();
                throw;
            }
        }

        public async Task<ApiResponse<bool>> DeleteEmployeeAsync(int employeeId, int deletedBy)
        {
            var emp = await _unitOfWork.Employees.GetByIdAsync(employeeId);
            if (emp == null || !emp.IsActive)
            {
                return ApiResponse<bool>.Fail("Employee not found", 404);
            }

            await _unitOfWork.Employees.SoftDeleteAsync(employeeId, deletedBy);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Employee deleted successfully");
        }

        public async Task<ApiResponse<bool>> AssignBranchesAsync(AssignEmployeeBranchesRequest request, int updatedBy)
        {
            var emp = await _unitOfWork.Employees.GetByIdAsync(request.EmployeeId);
            if (emp == null || !emp.IsActive)
            {
                return ApiResponse<bool>.Fail("Employee not found", 404);
            }

            await _unitOfWork.Employees.UpdateEmployeeBranchesAsync(request.EmployeeId, request.BranchIds, updatedBy);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Employee branches updated successfully");
        }
    }
}
