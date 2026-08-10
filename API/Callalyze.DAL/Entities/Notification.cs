using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class Notification
{
    public int NotificationId { get; set; }

    public int CompanyId { get; set; }

    public int EmployeeId { get; set; }

    public string Title { get; set; } = null!;

    public string? Message { get; set; }

    public string Type { get; set; } = null!;

    public bool IsRead { get; set; }

    public DateTime? ReadAt { get; set; }

    public string? Data { get; set; }

    public DateTime? SentAt { get; set; }

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
