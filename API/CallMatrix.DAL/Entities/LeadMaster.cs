using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class LeadMaster
{
    public int LeadId { get; set; }

    public int CompanyId { get; set; }

    public string FirstName { get; set; } = null!;

    public string? LastName { get; set; }

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string Status { get; set; } = null!;

    public string? Source { get; set; }

    public int? AssignedTo { get; set; }

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual EmployeeMaster? AssignedToNavigation { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<CustomerMaster> CustomerMasters { get; set; } = new List<CustomerMaster>();

    public virtual ICollection<FollowUp> FollowUps { get; set; } = new List<FollowUp>();

    public virtual ICollection<NoteMaster> NoteMasters { get; set; } = new List<NoteMaster>();

    public virtual ICollection<TaskMaster> TaskMasters { get; set; } = new List<TaskMaster>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
