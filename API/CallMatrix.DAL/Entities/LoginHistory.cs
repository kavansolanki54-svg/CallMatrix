using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class LoginHistory
{
    public int LoginHistoryId { get; set; }

    public int CompanyId { get; set; }

    public int EmployeeId { get; set; }

    public DateTime LoginAt { get; set; }

    public DateTime? LogoutAt { get; set; }

    public string? Ipaddress { get; set; }

    public string? UserAgent { get; set; }

    public string? DeviceInfo { get; set; }

    public string Status { get; set; } = null!;

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
