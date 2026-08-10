using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class CustomerMaster
{
    public int CustomerId { get; set; }

    public int CompanyId { get; set; }

    public string FirstName { get; set; } = null!;

    public string? LastName { get; set; }

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public int? LeadId { get; set; }

    public string? Address { get; set; }

    public string? City { get; set; }

    public string? State { get; set; }

    public string? Country { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual ICollection<CallMaster> CallMasters { get; set; } = new List<CallMaster>();

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual ICollection<ContactMaster> ContactMasters { get; set; } = new List<ContactMaster>();

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<FollowUp> FollowUps { get; set; } = new List<FollowUp>();

    public virtual LeadMaster? Lead { get; set; }

    public virtual ICollection<NoteMaster> NoteMasters { get; set; } = new List<NoteMaster>();

    public virtual ICollection<TaskMaster> TaskMasters { get; set; } = new List<TaskMaster>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
