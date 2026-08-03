using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class FollowUp
{
    public int FollowUpId { get; set; }

    public int CompanyId { get; set; }

    public int? LeadId { get; set; }

    public int? CustomerId { get; set; }

    public DateTime ScheduledDate { get; set; }

    public DateTime? CompletedDate { get; set; }

    public string? Notes { get; set; }

    public string Status { get; set; } = null!;

    public int? AssignedTo { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual EmployeeMaster? AssignedToNavigation { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual CustomerMaster? Customer { get; set; }

    public virtual LeadMaster? Lead { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
