using Callalyze.BLL.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Callalyze.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class EnumsController : ControllerBase
    {
        private readonly IEnumService _enumService;

        public EnumsController(IEnumService enumService)
        {
            _enumService = enumService;
        }

        [HttpGet("{categoryId}")]
        public async Task<IActionResult> GetEnumValues(short categoryId)
        {
            var result = await _enumService.GetEnumValuesAsync(categoryId);
            return StatusCode(result.StatusCode, result);
        }
    }
}
