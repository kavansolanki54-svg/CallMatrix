using AutoMapper;
using Callalyze.DAL.Entities;
using Callalyze.DTO.Request.CRM;
using Callalyze.DTO.Response.CRM;

namespace Callalyze.DTO.Mappings
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
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
        }
    }
}
