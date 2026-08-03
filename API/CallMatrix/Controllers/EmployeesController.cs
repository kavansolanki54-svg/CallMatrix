using CallMatrix.BLL.Interfaces;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Employee;
using CallMatrix.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CallMatrix.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class EmployeesController : ControllerBase
    {
        private readonly IEmployeeService _employeeService;

        public EmployeesController(IEmployeeService employeeService)
        {
            _employeeService = employeeService;
        }

        [HttpGet]
        [RequirePermission("Employee", "CanView")]
        public async Task<IActionResult> GetEmployees([FromQuery] PaginationRequest request)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _employeeService.GetEmployeesAsync(request, companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpGet("{id}")]
        [RequirePermission("Employee", "CanView")]
        public async Task<IActionResult> GetEmployeeById(int id)
        {
            var result = await _employeeService.GetEmployeeByIdAsync(id);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Employee", "CanAdd")]
        public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeRequest request)
        {
            int createdBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _employeeService.CreateEmployeeAsync(request, createdBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPut]
        [RequirePermission("Employee", "CanEdit")]
        public async Task<IActionResult> UpdateEmployee([FromBody] UpdateEmployeeRequest request)
        {
            int updatedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _employeeService.UpdateEmployeeAsync(request, updatedBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpDelete("{id}")]
        [RequirePermission("Employee", "CanDelete")]
        public async Task<IActionResult> DeleteEmployee(int id)
        {
            int deletedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _employeeService.DeleteEmployeeAsync(id, deletedBy);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost("assign-branches")]
        [RequirePermission("Employee", "CanEdit")]
        public async Task<IActionResult> AssignBranches([FromBody] AssignEmployeeBranchesRequest request)
        {
            int updatedBy = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            var result = await _employeeService.AssignBranchesAsync(request, updatedBy);
            return StatusCode(result.StatusCode, result);
        }
    }
}
