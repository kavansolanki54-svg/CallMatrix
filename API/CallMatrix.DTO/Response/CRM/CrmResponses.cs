namespace CallMatrix.DTO.Response.CRM
{
    public class LeadResponse
    {
        public int LeadId { get; set; }
        public int CompanyId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Source { get; set; }
        public int? AssignedTo { get; set; }
        public string? AssignedToName { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CustomerResponse
    {
        public int CustomerId { get; set; }
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
        public DateTime CreatedAt { get; set; }
    }

    public class ContactResponse
    {
        public int ContactId { get; set; }
        public int CompanyId { get; set; }
        public int? CustomerId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? Designation { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class FollowUpResponse
    {
        public int FollowUpId { get; set; }
        public int CompanyId { get; set; }
        public int? LeadId { get; set; }
        public int? CustomerId { get; set; }
        public DateTime ScheduledDate { get; set; }
        public DateTime? CompletedDate { get; set; }
        public string? Notes { get; set; }
        public string Status { get; set; } = string.Empty;
        public int? AssignedTo { get; set; }
        public string? AssignedToName { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class TaskResponse
    {
        public int TaskId { get; set; }
        public int CompanyId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? LeadId { get; set; }
        public int? CustomerId { get; set; }
        public int AssignedTo { get; set; }
        public string? AssignedToName { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? CompletedDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public string Priority { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class TimelineItemResponse
    {
        public string ItemType { get; set; } = string.Empty; // Call, Note, FollowUp, Task
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public string? PerformedByName { get; set; }
    }
}
