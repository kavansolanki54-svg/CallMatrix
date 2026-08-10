using Callalyze.BLL.Interfaces;
using Callalyze.DAL.UnitOfWork;
using Callalyze.DTO.Common;
using Callalyze.DTO.Response.Enum;

namespace Callalyze.BLL.Services
{
    public class EnumService : IEnumService
    {
        private readonly IUnitOfWork _unitOfWork;

        public EnumService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ApiResponse<IEnumerable<EnumResponse>>> GetEnumValuesAsync(short categoryId)
        {
            var enums = await _unitOfWork.EnumTypes.GetEnumTypesByCategoryIdAsync(categoryId);
            var dtos = enums.Select(e => new EnumResponse
            {
                Value = e.EnumId.ToString(),
                Label = e.EnumName
            });

            return ApiResponse<IEnumerable<EnumResponse>>.Ok(dtos, "Enums retrieved successfully");
        }
    }
}
