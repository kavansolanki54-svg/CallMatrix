using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class CallMaster
{
    public int CallId { get; set; }

    public int CompanyId { get; set; }

    public string PhoneNumber { get; set; } = null!;

    public string? ContactName { get; set; }

    public int? Duration { get; set; }

    public string CallType { get; set; } = null!;

    public DateTime CallDateTime { get; set; }

    public int EmployeeId { get; set; }

    public int? DeviceId { get; set; }

    public int? CustomerId { get; set; }

    public DateTime? SyncedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual ICollection<CallRecording> CallRecordings { get; set; } = new List<CallRecording>();

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual CustomerMaster? Customer { get; set; }

    public virtual UserDevice? Device { get; set; }

    public virtual EmployeeMaster Employee { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
