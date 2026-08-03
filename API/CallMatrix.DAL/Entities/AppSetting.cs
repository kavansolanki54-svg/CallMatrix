using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class AppSetting
{
    public int SettingId { get; set; }

    public int CompanyId { get; set; }

    public string SettingKey { get; set; } = null!;

    public string? SettingValue { get; set; }

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
