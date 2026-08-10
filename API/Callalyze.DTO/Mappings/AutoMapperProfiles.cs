using AutoMapper;
using Callalyze.DAL.Entities;
using Callalyze.DTO.Request.Auth;
using Callalyze.DTO.Request.Calls;
using Callalyze.DTO.Request.CRM;
using Callalyze.DTO.Request.Device;
using Callalyze.DTO.Request.Employee;
using Callalyze.DTO.Request.Role;
using Callalyze.DTO.Response.Auth;
using Callalyze.DTO.Response.Calls;
using Callalyze.DTO.Response.CRM;
using Callalyze.DTO.Response.Device;
using Callalyze.DTO.Response.Employee;
using Callalyze.DTO.Response.Menu;
using Callalyze.DTO.Response.Role;

namespace Callalyze.DTO.Mappings
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
            CreateMap<CallMaster, CallLogResponse>()
                .ForMember(dest => dest.EmployeeName, opt => opt.MapFrom(src => src.Employee.EmployeeName))
                .ForMember(dest => dest.HasRecording, opt => opt.MapFrom(src => src.CallRecordings.Any(r => r.IsActive)))
                .ForMember(dest => dest.RecordingUrl, opt => opt.MapFrom(src => src.CallRecordings.Where(r => r.IsActive).Select(r => r.FileUrl).FirstOrDefault()));
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
