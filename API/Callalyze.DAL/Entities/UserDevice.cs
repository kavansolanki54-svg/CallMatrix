using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class UserDevice
{
    public int UserDeviceId { get; set; }

    public int CompanyId { get; set; }

    public int EmployeeId { get; set; }

    public string DeviceId { get; set; } = null!;

    public string? Imei { get; set; }

    public string? Manufacturer { get; set; }

    public string? Model { get; set; }

    public string? Osversion { get; set; }

    public string? AppVersion { get; set; }

    public int? BatteryLevel { get; set; }

    public string? Ipaddress { get; set; }

    public DateTime? LastSyncAt { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public bool IsOnline { get; set; }

    public bool IsApproved { get; set; }

    public bool IsBlocked { get; set; }

    public string? Status { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual ICollection<CallMaster> CallMasters { get; set; } = new List<CallMaster>();

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster Employee { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
