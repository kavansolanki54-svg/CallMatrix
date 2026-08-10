namespace Callalyze.DTO.Request.CRM
{
    public class CreateLeadRequest
    {
        public int CompanyId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string Status { get; set; } = "New";
        public string? Source { get; set; }
        public int? AssignedTo { get; set; }
        public string? Description { get; set; }
    }

    public class UpdateLeadStatusRequest
    {
        public int LeadId { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    public class AssignLeadRequest
    {
        public int LeadId { get; set; }
        public int AssignedTo { get; set; }
    }

    public class CreateCustomerRequest
    {
        public int CompanyId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public int? LeadId { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public string? State { get; set; }
        public string? Country { get; set; }
    }

    public class CreateContactRequest
    {
        public int CompanyId { get; set; }
        public int? CustomerId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Designation { get; set; }
    }

    public class CreateFollowUpRequest
    {
        public int CompanyId { get; set; }
        public int? LeadId { get; set; }
        public int? CustomerId { get; set; }
        public DateTime ScheduledDate { get; set; }
        public string? Notes { get; set; }
        public int? AssignedTo { get; set; }
    }

    public class CreateTaskRequest
    {
        public int CompanyId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? LeadId { get; set; }
        public int? CustomerId { get; set; }
        public int AssignedTo { get; set; }
        public DateTime? DueDate { get; set; }
        public string Priority { get; set; } = "Medium";
    }
}
