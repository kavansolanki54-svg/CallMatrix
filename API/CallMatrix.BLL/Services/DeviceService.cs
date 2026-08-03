using AutoMapper;
using CallMatrix.BLL.Interfaces;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.Device;
using CallMatrix.DTO.Response.Device;

namespace CallMatrix.BLL.Services
{
    public class DeviceService : IDeviceService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public DeviceService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<PaginatedResponse<DeviceResponse>>> GetDevicesAsync(PaginationRequest request, int companyId)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;

            var (items, totalCount) = await _unitOfWork.Devices.GetPagedAsync(
                request.Page,
                request.PageSize,
                request.Search,
                request.SortBy ?? "LastSyncAt",
                request.SortOrder ?? "DESC",
                filters);

            var dtos = _mapper.Map<IEnumerable<DeviceResponse>>(items);
            var result = new PaginatedResponse<DeviceResponse>(dtos, totalCount, request.Page, request.PageSize);

            return ApiResponse<PaginatedResponse<DeviceResponse>>.Ok(result, "Devices retrieved successfully");
        }

        public async Task<ApiResponse<DeviceResponse>> RegisterDeviceAsync(RegisterDeviceRequest request, int employeeId)
        {
            var existingDevice = await _unitOfWork.Devices.GetByDeviceIdAsync(request.DeviceId);
            if (existingDevice != null)
            {
                var existingDto = _mapper.Map<DeviceResponse>(existingDevice);
                return ApiResponse<DeviceResponse>.Ok(existingDto, "Device already registered");
            }

            var entity = _mapper.Map<UserDevice>(request);
            entity.EmployeeId = employeeId;
            entity.IsOnline = true;
            entity.IsApproved = true; // Auto-approve on registration
            entity.IsBlocked = false;
            entity.Status = "Active";
            entity.LastSyncAt = DateTime.Now;
            entity.CreatedAt = DateTime.Now;
            entity.CreatedBy = employeeId;
            entity.IsActive = true;

            await _unitOfWork.Devices.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var dto = _mapper.Map<DeviceResponse>(entity);
            return ApiResponse<DeviceResponse>.Ok(dto, "Device registered successfully", 201);
        }

        public async Task<ApiResponse<bool>> UpdatePingAsync(UpdateDevicePingRequest request, int employeeId)
        {
            var device = await _unitOfWork.Devices.GetByDeviceIdAsync(request.DeviceId);
            if (device == null || !device.IsActive)
            {
                return ApiResponse<bool>.Fail("Device not registered or inactive", 404);
            }

            if (device.IsBlocked)
            {
                return ApiResponse<bool>.Fail("Device is blocked", 403);
            }

            device.BatteryLevel = request.BatteryLevel ?? device.BatteryLevel;
            device.Ipaddress = request.IPAddress ?? device.Ipaddress;
            device.Latitude = request.Latitude ?? device.Latitude;
            device.Longitude = request.Longitude ?? device.Longitude;
            device.IsOnline = request.IsOnline;
            device.LastSyncAt = DateTime.Now;
            device.UpdatedAt = DateTime.Now;
            device.UpdatedBy = employeeId;

            await _unitOfWork.Devices.UpdateAsync(device);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Device telemetry ping updated");
        }

        public async Task<ApiResponse<bool>> ApproveDeviceAsync(ApproveDeviceRequest request, int employeeId)
        {
            var device = await _unitOfWork.Devices.GetByIdAsync(request.UserDeviceId);
            if (device == null || !device.IsActive)
            {
                return ApiResponse<bool>.Fail("Device not found", 404);
            }

            device.IsApproved = request.IsApproved;
            device.Status = request.IsApproved ? "Active" : "Pending";
            device.UpdatedAt = DateTime.Now;
            device.UpdatedBy = employeeId;

            await _unitOfWork.Devices.UpdateAsync(device);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, $"Device approval status updated to {request.IsApproved}");
        }

        public async Task<ApiResponse<bool>> BlockDeviceAsync(BlockDeviceRequest request, int employeeId)
        {
            var device = await _unitOfWork.Devices.GetByIdAsync(request.UserDeviceId);
            if (device == null || !device.IsActive)
            {
                return ApiResponse<bool>.Fail("Device not found", 404);
            }

            device.IsBlocked = request.IsBlocked;
            device.Status = request.IsBlocked ? "Blocked" : "Active";
            device.UpdatedAt = DateTime.Now;
            device.UpdatedBy = employeeId;

            await _unitOfWork.Devices.UpdateAsync(device);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, $"Device blocked status updated to {request.IsBlocked}");
        }
    }
}
