using AutoMapper;
using CallMatrix.DAL.Entities;
using CallMatrix.DTO.Request.CRM;
using CallMatrix.DTO.Response.CRM;

namespace CallMatrix.DTO.Mappings
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
