using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class ActivityLog
{
    public int ActivityLogId { get; set; }

    public int CompanyId { get; set; }

    public int EmployeeId { get; set; }

    public string Action { get; set; } = null!;

    public string EntityType { get; set; } = null!;

    public int? EntityId { get; set; }

    public string? Description { get; set; }

    public string? Ipaddress { get; set; }

    public string? UserAgent { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster Employee { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
