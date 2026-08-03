using AutoMapper;
using CallMatrix.BLL.Interfaces;
using CallMatrix.DAL.Entities;
using CallMatrix.DAL.UnitOfWork;
using CallMatrix.DTO.Common;
using CallMatrix.DTO.Request.CRM;
using CallMatrix.DTO.Response.CRM;

namespace CallMatrix.BLL.Services
{
    public class LeadService : ILeadService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public LeadService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<PaginatedResponse<LeadResponse>>> GetLeadsAsync(PaginationRequest request, int companyId)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;

            var (items, totalCount) = await _unitOfWork.Leads.GetPagedAsync(
                request.Page,
                request.PageSize,
                request.Search,
                request.SortBy ?? "CreatedAt",
                request.SortOrder ?? "DESC",
                filters);

            var leadDtos = _mapper.Map<IEnumerable<LeadResponse>>(items);
            var result = new PaginatedResponse<LeadResponse>(leadDtos, totalCount, request.Page, request.PageSize);

            return ApiResponse<PaginatedResponse<LeadResponse>>.Ok(result, "Leads retrieved successfully");
        }

        public async Task<ApiResponse<LeadResponse>> CreateLeadAsync(CreateLeadRequest request, int employeeId)
        {
            var entity = _mapper.Map<LeadMaster>(request);
            entity.CreatedAt = DateTime.Now;
            entity.CreatedBy = employeeId;
            entity.IsActive = true;

            await _unitOfWork.Leads.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var response = _mapper.Map<LeadResponse>(entity);
            return ApiResponse<LeadResponse>.Ok(response, "Lead created successfully", 201);
        }

        public async Task<ApiResponse<bool>> UpdateLeadStatusAsync(UpdateLeadStatusRequest request, int employeeId)
        {
            var lead = await _unitOfWork.Leads.GetByIdAsync(request.LeadId);
            if (lead == null || !lead.IsActive)
            {
                return ApiResponse<bool>.Fail("Lead not found", 404);
            }

            lead.Status = request.Status;
            lead.UpdatedAt = DateTime.Now;
            lead.UpdatedBy = employeeId;

            await _unitOfWork.Leads.UpdateAsync(lead);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Lead status updated successfully");
        }

        public async Task<ApiResponse<bool>> AssignLeadAsync(AssignLeadRequest request, int employeeId)
        {
            var lead = await _unitOfWork.Leads.GetByIdAsync(request.LeadId);
            if (lead == null || !lead.IsActive)
            {
                return ApiResponse<bool>.Fail("Lead not found", 404);
            }

            lead.AssignedTo = request.AssignedTo;
            lead.Status = "Assigned";
            lead.UpdatedAt = DateTime.Now;
            lead.UpdatedBy = employeeId;

            await _unitOfWork.Leads.UpdateAsync(lead);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.Ok(true, "Lead assigned successfully");
        }

        public async Task<ApiResponse<CustomerResponse>> ConvertLeadToCustomerAsync(int leadId, int employeeId)
        {
            var lead = await _unitOfWork.Leads.GetByIdAsync(leadId);
            if (lead == null || !lead.IsActive)
            {
                return ApiResponse<CustomerResponse>.Fail("Lead not found", 404);
            }

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                // 1. Update lead status
                lead.Status = "Converted";
                lead.UpdatedAt = DateTime.Now;
                lead.UpdatedBy = employeeId;
                await _unitOfWork.Leads.UpdateAsync(lead);

                // 2. Create customer record
                var customer = new CustomerMaster
                {
                    CompanyId = lead.CompanyId,
                    FirstName = lead.FirstName,
                    LastName = lead.LastName,
                    Email = lead.Email,
                    Phone = lead.Phone,
                    LeadId = lead.LeadId,
                    CreatedAt = DateTime.Now,
                    CreatedBy = employeeId,
                    IsActive = true
                };

                await _unitOfWork.Customers.AddAsync(customer);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitTransactionAsync();

                var customerDto = _mapper.Map<CustomerResponse>(customer);
                return ApiResponse<CustomerResponse>.Ok(customerDto, "Lead converted to customer successfully");
            }
            catch
            {
                await _unitOfWork.RollbackTransactionAsync();
                throw;
            }
        }

        public async Task<ApiResponse<List<TimelineItemResponse>>> GetLeadTimelineAsync(int leadId)
        {
            var timelineTuple = await _unitOfWork.Leads.GetLeadTimelineAsync(leadId);
            var timeline = timelineTuple.Select(x => new TimelineItemResponse
            {
                ItemType = x.ItemType,
                Title = x.Title,
                Description = x.Description,
                EventDate = x.EventDate,
                PerformedByName = x.PerformedByName
            }).ToList();

            return ApiResponse<List<TimelineItemResponse>>.Ok(timeline, "Timeline retrieved successfully");
        }
    }

    public class CustomerService : ICustomerService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMapper _mapper;

        public CustomerService(IUnitOfWork unitOfWork, IMapper mapper)
        {
            _unitOfWork = unitOfWork;
            _mapper = mapper;
        }

        public async Task<ApiResponse<PaginatedResponse<CustomerResponse>>> GetCustomersAsync(PaginationRequest request, int companyId)
        {
            var filters = request.Filters ?? new Dictionary<string, object>();
            filters["CompanyId"] = companyId;

            var (items, totalCount) = await _unitOfWork.Customers.GetPagedAsync(
                request.Page,
                request.PageSize,
                request.Search,
                request.SortBy ?? "CreatedAt",
                request.SortOrder ?? "DESC",
                filters);

            var dtos = _mapper.Map<IEnumerable<CustomerResponse>>(items);
            var result = new PaginatedResponse<CustomerResponse>(dtos, totalCount, request.Page, request.PageSize);

            return ApiResponse<PaginatedResponse<CustomerResponse>>.Ok(result, "Customers retrieved successfully");
        }

        public async Task<ApiResponse<CustomerResponse>> CreateCustomerAsync(CreateCustomerRequest request, int employeeId)
        {
            var entity = _mapper.Map<CustomerMaster>(request);
            entity.CreatedAt = DateTime.Now;
            entity.CreatedBy = employeeId;
            entity.IsActive = true;

            await _unitOfWork.Customers.AddAsync(entity);
            await _unitOfWork.SaveChangesAsync();

            var dto = _mapper.Map<CustomerResponse>(entity);
            return ApiResponse<CustomerResponse>.Ok(dto, "Customer created successfully", 201);
        }
    }
}
