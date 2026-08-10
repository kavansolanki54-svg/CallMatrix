using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class CompanyMaster
{
    public int CompanyId { get; set; }

    public string CompanyName { get; set; } = null!;

    public string CompanyCode { get; set; } = null!;

    public string? Industry { get; set; }

    public string? Website { get; set; }

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string? Address { get; set; }

    public string? Country { get; set; }

    public string? State { get; set; }

    public string? City { get; set; }

    public string? Pincode { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual ICollection<ActivityLog> ActivityLogs { get; set; } = new List<ActivityLog>();

    public virtual ICollection<AppSetting> AppSettings { get; set; } = new List<AppSetting>();

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<ErrorLog> ErrorLogs { get; set; } = new List<ErrorLog>();

    public virtual ICollection<BranchMaster> BranchMasters { get; set; } = new List<BranchMaster>();

    public virtual ICollection<CallMaster> CallMasters { get; set; } = new List<CallMaster>();

    public virtual ICollection<CallRecording> CallRecordings { get; set; } = new List<CallRecording>();

    public virtual ICollection<ContactMaster> ContactMasters { get; set; } = new List<ContactMaster>();

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<CustomerMaster> CustomerMasters { get; set; } = new List<CustomerMaster>();

    public virtual ICollection<DepartmentMaster> DepartmentMasters { get; set; } = new List<DepartmentMaster>();

    public virtual ICollection<DesignationMaster> DesignationMasters { get; set; } = new List<DesignationMaster>();

    public virtual EmployeeMaster? EmployeeMaster { get; set; }

    public virtual ICollection<FollowUp> FollowUps { get; set; } = new List<FollowUp>();

    public virtual ICollection<LeadMaster> LeadMasters { get; set; } = new List<LeadMaster>();

    public virtual ICollection<LoginHistory> LoginHistories { get; set; } = new List<LoginHistory>();

    public virtual ICollection<MenuMaster> MenuMasters { get; set; } = new List<MenuMaster>();

    public virtual ICollection<NoteMaster> NoteMasters { get; set; } = new List<NoteMaster>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

    public virtual ICollection<RoleMaster> RoleMasters { get; set; } = new List<RoleMaster>();

    public virtual ICollection<TaskMaster> TaskMasters { get; set; } = new List<TaskMaster>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }

    public virtual ICollection<UserDevice> UserDevices { get; set; } = new List<UserDevice>();
}
