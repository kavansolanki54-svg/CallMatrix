using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class EmployeeMaster
{
    public int EmployeeId { get; set; }

    public int CompanyId { get; set; }

    public int? DepartmentId { get; set; }

    public int? DesignationId { get; set; }

    public int? RoleId { get; set; }

    public string EmployeeCode { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string? MiddleName { get; set; }

    public string? LastName { get; set; }

    public string EmployeeName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Password { get; set; }

    public string? ProfileImageUrl { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public bool Tenant { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual ICollection<ActivityLog> ActivityLogCreatedByNavigations { get; set; } = new List<ActivityLog>();

    public virtual ICollection<ActivityLog> ActivityLogEmployees { get; set; } = new List<ActivityLog>();

    public virtual ICollection<ActivityLog> ActivityLogUpdatedByNavigations { get; set; } = new List<ActivityLog>();

    public virtual ICollection<AppSetting> AppSettingCreatedByNavigations { get; set; } = new List<AppSetting>();

    public virtual ICollection<AppSetting> AppSettingUpdatedByNavigations { get; set; } = new List<AppSetting>();

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<ErrorLog> ErrorLogs { get; set; } = new List<ErrorLog>();

    public virtual ICollection<BranchMaster> BranchMasterCreatedByNavigations { get; set; } = new List<BranchMaster>();

    public virtual ICollection<BranchMaster> BranchMasterUpdatedByNavigations { get; set; } = new List<BranchMaster>();

    public virtual ICollection<CallMaster> CallMasterCreatedByNavigations { get; set; } = new List<CallMaster>();

    public virtual ICollection<CallMaster> CallMasterEmployees { get; set; } = new List<CallMaster>();

    public virtual ICollection<CallMaster> CallMasterUpdatedByNavigations { get; set; } = new List<CallMaster>();

    public virtual ICollection<CallRecording> CallRecordingCreatedByNavigations { get; set; } = new List<CallRecording>();

    public virtual ICollection<CallRecording> CallRecordingUpdatedByNavigations { get; set; } = new List<CallRecording>();

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual ICollection<CompanyMaster> CompanyMasterCreatedByNavigations { get; set; } = new List<CompanyMaster>();

    public virtual ICollection<CompanyMaster> CompanyMasterUpdatedByNavigations { get; set; } = new List<CompanyMaster>();

    public virtual ICollection<ContactMaster> ContactMasterCreatedByNavigations { get; set; } = new List<ContactMaster>();

    public virtual ICollection<ContactMaster> ContactMasterUpdatedByNavigations { get; set; } = new List<ContactMaster>();

    public virtual ICollection<CustomerMaster> CustomerMasterCreatedByNavigations { get; set; } = new List<CustomerMaster>();

    public virtual ICollection<CustomerMaster> CustomerMasterUpdatedByNavigations { get; set; } = new List<CustomerMaster>();

    public virtual DepartmentMaster? Department { get; set; }

    public virtual ICollection<DepartmentMaster> DepartmentMasterCreatedByNavigations { get; set; } = new List<DepartmentMaster>();

    public virtual ICollection<DepartmentMaster> DepartmentMasterUpdatedByNavigations { get; set; } = new List<DepartmentMaster>();

    public virtual DesignationMaster? Designation { get; set; }

    public virtual ICollection<DesignationMaster> DesignationMasterCreatedByNavigations { get; set; } = new List<DesignationMaster>();

    public virtual ICollection<DesignationMaster> DesignationMasterUpdatedByNavigations { get; set; } = new List<DesignationMaster>();

    public virtual ICollection<EmployeeBranch> EmployeeBranchCreatedByNavigations { get; set; } = new List<EmployeeBranch>();

    public virtual ICollection<EmployeeBranch> EmployeeBranchEmployees { get; set; } = new List<EmployeeBranch>();

    public virtual ICollection<EmployeeBranch> EmployeeBranchUpdatedByNavigations { get; set; } = new List<EmployeeBranch>();

    public virtual ICollection<FollowUp> FollowUpAssignedToNavigations { get; set; } = new List<FollowUp>();

    public virtual ICollection<FollowUp> FollowUpCreatedByNavigations { get; set; } = new List<FollowUp>();

    public virtual ICollection<FollowUp> FollowUpUpdatedByNavigations { get; set; } = new List<FollowUp>();

    public virtual ICollection<LeadMaster> LeadMasterAssignedToNavigations { get; set; } = new List<LeadMaster>();

    public virtual ICollection<LeadMaster> LeadMasterCreatedByNavigations { get; set; } = new List<LeadMaster>();

    public virtual ICollection<LeadMaster> LeadMasterUpdatedByNavigations { get; set; } = new List<LeadMaster>();

    public virtual ICollection<LoginHistory> LoginHistoryCreatedByNavigations { get; set; } = new List<LoginHistory>();

    public virtual ICollection<LoginHistory> LoginHistoryEmployees { get; set; } = new List<LoginHistory>();

    public virtual ICollection<LoginHistory> LoginHistoryUpdatedByNavigations { get; set; } = new List<LoginHistory>();

    public virtual ICollection<MenuMaster> MenuMasterCreatedByNavigations { get; set; } = new List<MenuMaster>();

    public virtual ICollection<MenuMaster> MenuMasterUpdatedByNavigations { get; set; } = new List<MenuMaster>();

    public virtual ICollection<NoteMaster> NoteMasterCreatedByNavigations { get; set; } = new List<NoteMaster>();

    public virtual ICollection<NoteMaster> NoteMasterUpdatedByNavigations { get; set; } = new List<NoteMaster>();

    public virtual ICollection<Notification> NotificationCreatedByNavigations { get; set; } = new List<Notification>();

    public virtual ICollection<Notification> NotificationEmployees { get; set; } = new List<Notification>();

    public virtual ICollection<Notification> NotificationUpdatedByNavigations { get; set; } = new List<Notification>();

    public virtual ICollection<RefreshToken> RefreshTokenCreatedByNavigations { get; set; } = new List<RefreshToken>();

    public virtual ICollection<RefreshToken> RefreshTokenEmployees { get; set; } = new List<RefreshToken>();

    public virtual ICollection<RefreshToken> RefreshTokenUpdatedByNavigations { get; set; } = new List<RefreshToken>();

    public virtual RoleMaster Role { get; set; } = null!;

    public virtual ICollection<RoleMaster> RoleMasterCreatedByNavigations { get; set; } = new List<RoleMaster>();

    public virtual ICollection<RoleMaster> RoleMasterUpdatedByNavigations { get; set; } = new List<RoleMaster>();

    public virtual ICollection<RolePermission> RolePermissionCreatedByNavigations { get; set; } = new List<RolePermission>();

    public virtual ICollection<RolePermission> RolePermissionUpdatedByNavigations { get; set; } = new List<RolePermission>();

    public virtual ICollection<TaskMaster> TaskMasterAssignedToNavigations { get; set; } = new List<TaskMaster>();

    public virtual ICollection<TaskMaster> TaskMasterCreatedByNavigations { get; set; } = new List<TaskMaster>();

    public virtual ICollection<TaskMaster> TaskMasterUpdatedByNavigations { get; set; } = new List<TaskMaster>();

    public virtual ICollection<UserDevice> UserDeviceCreatedByNavigations { get; set; } = new List<UserDevice>();

    public virtual ICollection<UserDevice> UserDeviceEmployees { get; set; } = new List<UserDevice>();

    public virtual ICollection<UserDevice> UserDeviceUpdatedByNavigations { get; set; } = new List<UserDevice>();
}
