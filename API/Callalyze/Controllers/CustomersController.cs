using Callalyze.BLL.Interfaces;
using Callalyze.DTO.Common;
using Callalyze.DTO.Request.CRM;
using Callalyze.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CustomersController : ControllerBase
    {
        private readonly ICustomerService _customerService;

        public CustomersController(ICustomerService customerService)
        {
            _customerService = customerService;
        }

        [HttpGet]
        [RequirePermission("Customer", "CanView")]
        public async Task<IActionResult> GetCustomers([FromQuery] PaginationRequest request)
        {
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            var result = await _customerService.GetCustomersAsync(request, companyId);
            return StatusCode(result.StatusCode, result);
        }

        [HttpPost]
        [RequirePermission("Customer", "CanAdd")]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            int employeeId = int.Parse(User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value);
            int companyId = int.Parse(User.FindFirst("CompanyId")!.Value);
            request.CompanyId = companyId;

            var result = await _customerService.CreateCustomerAsync(request, employeeId);
            return StatusCode(result.StatusCode, result);
        }
    }
}
