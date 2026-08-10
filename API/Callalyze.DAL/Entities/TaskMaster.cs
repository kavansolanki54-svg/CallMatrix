using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class TaskMaster
{
    public int TaskId { get; set; }

    public int CompanyId { get; set; }

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public int? LeadId { get; set; }

    public int? CustomerId { get; set; }

    public int AssignedTo { get; set; }

    public DateTime? DueDate { get; set; }

    public DateTime? CompletedDate { get; set; }

    public string Status { get; set; } = null!;

    public string Priority { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual EmployeeMaster AssignedToNavigation { get; set; } = null!;

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual CustomerMaster? Customer { get; set; }

    public virtual LeadMaster? Lead { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
