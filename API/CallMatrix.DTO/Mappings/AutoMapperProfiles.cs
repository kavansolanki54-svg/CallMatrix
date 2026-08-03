using AutoMapper;
using CallMatrix.DAL.Entities;
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

namespace CallMatrix.DTO.Mappings
{
    public class AutoMapperProfiles : Profile
    {
        public AutoMapperProfiles()
        {
            // Lead Mappings
            CreateMap<LeadMaster, LeadResponse>();
            CreateMap<CreateLeadRequest, LeadMaster>();

            // Customer Mappings
            CreateMap<CustomerMaster, CustomerResponse>();
            CreateMap<CreateCustomerRequest, CustomerMaster>();

            // Contact Mappings
            CreateMap<ContactMaster, ContactResponse>();
            CreateMap<CreateContactRequest, ContactMaster>();

            // FollowUp Mappings
            CreateMap<FollowUp, FollowUpResponse>();
            CreateMap<CreateFollowUpRequest, FollowUp>();

            // Task Mappings
            CreateMap<TaskMaster, TaskResponse>();
            CreateMap<CreateTaskRequest, TaskMaster>();

            // Call Mappings
            CreateMap<CallMaster, CallLogResponse>();
            CreateMap<CreateCallLogRequest, CallMaster>();
            CreateMap<CallRecording, CallRecordingResponse>();
            CreateMap<UploadCallRecordingRequest, CallRecording>();

            // Device Mappings
            CreateMap<UserDevice, DeviceResponse>()
                .ForMember(dest => dest.IMEI, opt => opt.MapFrom(src => src.Imei))
                .ForMember(dest => dest.OSVersion, opt => opt.MapFrom(src => src.Osversion))
                .ForMember(dest => dest.IPAddress, opt => opt.MapFrom(src => src.Ipaddress));

            CreateMap<RegisterDeviceRequest, UserDevice>()
                .ForMember(dest => dest.Imei, opt => opt.MapFrom(src => src.IMEI))
                .ForMember(dest => dest.Osversion, opt => opt.MapFrom(src => src.OSVersion));

            // User / Employee Mappings
            CreateMap<EmployeeMaster, UserInfoDto>()
                .ForMember(dest => dest.RoleName, opt => opt.Ignore());

            CreateMap<EmployeeMaster, EmployeeDetailResponse>()
                .ForMember(dest => dest.MobileNo, opt => opt.MapFrom(src => src.Phone))
                .ForMember(dest => dest.Tenant, opt => opt.MapFrom(src => src.Tenant ? 1 : 0));

            CreateMap<CreateEmployeeRequest, EmployeeMaster>();

            // Role Mappings
            CreateMap<RoleMaster, RoleResponse>();
            CreateMap<CreateRoleRequest, RoleMaster>();
            CreateMap<RolePermission, RolePermissionItemResponse>();
        }
    }
}
