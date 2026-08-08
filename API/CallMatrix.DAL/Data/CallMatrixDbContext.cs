using System;
using System.Collections.Generic;
using CallMatrix.DAL.Entities;
using Microsoft.EntityFrameworkCore;

namespace CallMatrix.DAL.Data;

public partial class CallMatrixDbContext : DbContext
{
    private readonly ICurrentUserService? _currentUserService;

    public CallMatrixDbContext(DbContextOptions<CallMatrixDbContext> options, ICurrentUserService? currentUserService = null)
        : base(options)
    {
        _currentUserService = currentUserService;
    }

    public virtual DbSet<ActivityLog> ActivityLogs { get; set; }

    public virtual DbSet<AppSetting> AppSettings { get; set; }

    public virtual DbSet<AuditLog> AuditLogs { get; set; }

    public virtual DbSet<BranchMaster> BranchMasters { get; set; }

    public virtual DbSet<CallMaster> CallMasters { get; set; }

    public virtual DbSet<CallRecording> CallRecordings { get; set; }

    public virtual DbSet<ApiKeySetting> ApiKeys { get; set; }

    public virtual DbSet<CompanyMaster> CompanyMasters { get; set; }

    public virtual DbSet<ContactMaster> ContactMasters { get; set; }

    public virtual DbSet<CustomerMaster> CustomerMasters { get; set; }

    public virtual DbSet<DepartmentMaster> DepartmentMasters { get; set; }

    public virtual DbSet<DesignationMaster> DesignationMasters { get; set; }

    public virtual DbSet<EmployeeBranch> EmployeeBranches { get; set; }

    public virtual DbSet<EmployeeMaster> EmployeeMasters { get; set; }

    public virtual DbSet<EnumCategory> EnumCategories { get; set; }

    public virtual DbSet<EnumMaster> EnumMasters { get; set; }

    public virtual DbSet<ErrorLog> ErrorLogs { get; set; }

    public virtual DbSet<FollowUp> FollowUps { get; set; }

    public virtual DbSet<LeadMaster> LeadMasters { get; set; }

    public virtual DbSet<LoginHistory> LoginHistories { get; set; }

    public virtual DbSet<MenuMaster> MenuMasters { get; set; }

    public virtual DbSet<NoteMaster> NoteMasters { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<RefreshToken> RefreshTokens { get; set; }

    public virtual DbSet<RoleMaster> RoleMasters { get; set; }

    public virtual DbSet<RolePermission> RolePermissions { get; set; }

    public virtual DbSet<TaskMaster> TaskMasters { get; set; }

    public virtual DbSet<UserDevice> UserDevices { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ActivityLog>(entity =>
        {
            entity.ToTable("ActivityLog");

            entity.HasIndex(e => e.CompanyId, "IX_ActivityLog_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CreatedAt, "IX_ActivityLog_CreatedAt")
                .IsDescending()
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_ActivityLog_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.EntityType, e.EntityId }, "IX_ActivityLog_EntityType_EntityId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.Action).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.EntityType).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.Ipaddress)
                .HasMaxLength(100)
                .HasColumnName("IPAddress");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.UserAgent).HasMaxLength(500);

            entity.HasOne(d => d.Company).WithMany(p => p.ActivityLogs)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ActivityLog_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.ActivityLogCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_ActivityLog_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.ActivityLogEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ActivityLog_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.ActivityLogUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_ActivityLog_UpdatedBy");
        });

        modelBuilder.Entity<AppSetting>(entity =>
        {
            entity.HasKey(e => e.SettingId);

            entity.HasIndex(e => e.CompanyId, "IX_AppSettings_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.SettingKey }, "IX_AppSettings_SettingKey").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.SettingKey, "UQ_AppSettings_SettingKey").IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.SettingKey).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.AppSettings)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AppSettings_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.AppSettingCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_AppSettings_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.AppSettingUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_AppSettings_UpdatedBy");
        });

        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.ToTable("AuditLog");

            entity.HasIndex(e => e.Action, "IX_AuditLog_Action");

            entity.HasIndex(e => e.CompanyId, "IX_AuditLog_CompanyId");

            entity.HasIndex(e => e.EmployeeId, "IX_AuditLog_EmployeeId");

            entity.HasIndex(e => new { e.TableName, e.RecordId }, "IX_AuditLog_TableName_RecordId");

            entity.HasIndex(e => e.Timestamp, "IX_AuditLog_Timestamp").IsDescending();

            entity.Property(e => e.Action).HasMaxLength(50);
            entity.Property(e => e.TableName).HasMaxLength(200);
            entity.Property(e => e.Timestamp)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_AuditLog_CompanyMaster");

            entity.HasOne(d => d.Employee).WithMany(p => p.AuditLogs)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_AuditLog_EmployeeMaster");
        });

        modelBuilder.Entity<BranchMaster>(entity =>
        {
            entity.HasKey(e => e.BranchId);

            entity.ToTable("BranchMaster");

            entity.HasIndex(e => e.BranchCode, "IX_BranchMaster_BranchCode").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_BranchMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.BranchCode).HasMaxLength(50);
            entity.Property(e => e.BranchName).HasMaxLength(200);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.Country).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Pincode).HasMaxLength(20);
            entity.Property(e => e.State).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.BranchMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_BranchMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.BranchMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_BranchMaster_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.BranchMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_BranchMaster_UpdatedBy");
        });

        modelBuilder.Entity<CallMaster>(entity =>
        {
            entity.HasKey(e => e.CallId);

            entity.ToTable("CallMaster");

            entity.HasIndex(e => e.CallDateTime, "IX_CallMaster_CallDateTime")
                .IsDescending()
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.CallType }, "IX_CallMaster_CallType").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_CallMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.EmployeeId, e.CallDateTime }, "IX_CallMaster_CompanyId_EmployeeId_CallDateTime")
                .IsDescending(false, false, true)
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CustomerId, "IX_CallMaster_CustomerId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DeviceId, "IX_CallMaster_DeviceId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_CallMaster_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.PhoneNumber, "IX_CallMaster_PhoneNumber").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CallDateTime).HasColumnType("datetime");
            entity.Property(e => e.CallType).HasMaxLength(50);
            entity.Property(e => e.ContactName).HasMaxLength(200);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Duration).HasDefaultValue(0);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.PhoneNumber).HasMaxLength(20);
            entity.Property(e => e.SyncedAt).HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.CallMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CallMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.CallMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_CallMaster_CreatedBy");

            entity.HasOne(d => d.Customer).WithMany(p => p.CallMasters)
                .HasForeignKey(d => d.CustomerId)
                .HasConstraintName("FK_CallMaster_CustomerMaster");

            entity.HasOne(d => d.Device).WithMany(p => p.CallMasters)
                .HasForeignKey(d => d.DeviceId)
                .HasConstraintName("FK_CallMaster_UserDevice");

            entity.HasOne(d => d.Employee).WithMany(p => p.CallMasterEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CallMaster_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.CallMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_CallMaster_UpdatedBy");
        });

        modelBuilder.Entity<CallRecording>(entity =>
        {
            entity.ToTable("CallRecording");

            entity.HasIndex(e => e.CallId, "IX_CallRecording_CallId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_CallRecording_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.UploadStatus, "IX_CallRecording_PendingUploads").HasFilter("(([UploadStatus] IN ('Pending', 'Failed')) AND [IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.UploadStatus }, "IX_CallRecording_UploadStatus").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Duration).HasDefaultValue(0);
            entity.Property(e => e.FileName).HasMaxLength(300);
            entity.Property(e => e.FilePath).HasMaxLength(500);
            entity.Property(e => e.FileSize).HasDefaultValue(0L);
            entity.Property(e => e.FileUrl).HasMaxLength(500);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.RecordingDate).HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.UploadStatus)
                .HasMaxLength(50)
                .HasDefaultValue("Pending");

            entity.HasOne(d => d.Call).WithMany(p => p.CallRecordings)
                .HasForeignKey(d => d.CallId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CallRecording_CallMaster");

            entity.HasOne(d => d.Company).WithMany(p => p.CallRecordings)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CallRecording_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.CallRecordingCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_CallRecording_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.CallRecordingUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_CallRecording_UpdatedBy");
        });

        modelBuilder.Entity<CompanyMaster>(entity =>
        {
            entity.HasKey(e => e.CompanyId);

            entity.ToTable("CompanyMaster");

            entity.HasIndex(e => e.CompanyCode, "IX_CompanyMaster_CompanyCode").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.IsActive, "IX_CompanyMaster_IsActive");

            entity.HasIndex(e => e.CompanyCode, "UQ_CompanyMaster_CompanyCode").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.CompanyCode).HasMaxLength(50);
            entity.Property(e => e.CompanyName).HasMaxLength(200);
            entity.Property(e => e.Country).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.Industry).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Pincode).HasMaxLength(20);
            entity.Property(e => e.State).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.Website).HasMaxLength(200);

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.CompanyMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_CompanyMaster_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.CompanyMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_CompanyMaster_UpdatedBy");
        });

        modelBuilder.Entity<ContactMaster>(entity =>
        {
            entity.HasKey(e => e.ContactId);

            entity.ToTable("ContactMaster");

            entity.HasIndex(e => e.CompanyId, "IX_ContactMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CustomerId, "IX_ContactMaster_CustomerId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Designation).HasMaxLength(100);
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LastName).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.ContactMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ContactMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.ContactMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_ContactMaster_CreatedBy");

            entity.HasOne(d => d.Customer).WithMany(p => p.ContactMasters)
                .HasForeignKey(d => d.CustomerId)
                .HasConstraintName("FK_ContactMaster_CustomerMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.ContactMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_ContactMaster_UpdatedBy");
        });

        modelBuilder.Entity<CustomerMaster>(entity =>
        {
            entity.HasKey(e => e.CustomerId);

            entity.ToTable("CustomerMaster");

            entity.HasIndex(e => e.CompanyId, "IX_CustomerMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Email, "IX_CustomerMaster_Email").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.LeadId, "IX_CustomerMaster_LeadId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Phone, "IX_CustomerMaster_Phone").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.City).HasMaxLength(100);
            entity.Property(e => e.Country).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LastName).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.State).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.CustomerMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_CustomerMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.CustomerMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_CustomerMaster_CreatedBy");

            entity.HasOne(d => d.Lead).WithMany(p => p.CustomerMasters)
                .HasForeignKey(d => d.LeadId)
                .HasConstraintName("FK_CustomerMaster_LeadMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.CustomerMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_CustomerMaster_UpdatedBy");
        });

        modelBuilder.Entity<DepartmentMaster>(entity =>
        {
            entity.HasKey(e => e.DepartmentId);

            entity.ToTable("DepartmentMaster");

            entity.HasIndex(e => e.CompanyId, "IX_DepartmentMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DepartmentCode, "IX_DepartmentMaster_DepartmentCode").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DepartmentCode).HasMaxLength(50);
            entity.Property(e => e.DepartmentName).HasMaxLength(100);
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.DepartmentMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DepartmentMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.DepartmentMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_DepartmentMaster_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.DepartmentMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_DepartmentMaster_UpdatedBy");
        });

        modelBuilder.Entity<DesignationMaster>(entity =>
        {
            entity.HasKey(e => e.DesignationId);

            entity.ToTable("DesignationMaster");

            entity.HasIndex(e => e.CompanyId, "IX_DesignationMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DepartmentId, "IX_DesignationMaster_DepartmentId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.DesignationName).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.DesignationMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DesignationMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.DesignationMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_DesignationMaster_CreatedBy");

            entity.HasOne(d => d.Department).WithMany(p => p.DesignationMasters)
                .HasForeignKey(d => d.DepartmentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DesignationMaster_DepartmentMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.DesignationMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_DesignationMaster_UpdatedBy");
        });

        modelBuilder.Entity<EmployeeBranch>(entity =>
        {
            entity.ToTable("EmployeeBranch");

            entity.HasIndex(e => e.BranchId, "IX_EmployeeBranch_BranchId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_EmployeeBranch_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.EmployeeId, e.BranchId }, "IX_EmployeeBranch_Employee_Branch_Unique")
                .IsUnique()
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.EmployeeId, e.IsPrimaryBranch }, "IX_EmployeeBranch_PrimaryBranch").HasFilter("([IsPrimaryBranch]=(1) AND [IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Branch).WithMany(p => p.EmployeeBranches)
                .HasForeignKey(d => d.BranchId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EmployeeBranch_BranchMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.EmployeeBranchCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_EmployeeBranch_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.EmployeeBranchEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EmployeeBranch_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.EmployeeBranchUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_EmployeeBranch_UpdatedBy");
        });

        modelBuilder.Entity<EmployeeMaster>(entity =>
        {
            entity.HasKey(e => e.EmployeeId);

            entity.ToTable("EmployeeMaster");

            entity.HasIndex(e => e.CompanyId, "IX_EmployeeMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DepartmentId, "IX_EmployeeMaster_DepartmentId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DesignationId, "IX_EmployeeMaster_DesignationId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Email, "IX_EmployeeMaster_Email").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeCode, "IX_EmployeeMaster_EmployeeCode").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.RoleId, "IX_EmployeeMaster_RoleId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.Tenant }, "IX_EmployeeMaster_Tenant").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_EmployeeMaster_TenantOwner_Unique")
                .IsUnique()
                .HasFilter("([Tenant]=(1) AND [IsActive]=(1))");

            entity.HasIndex(e => e.Email, "UQ_EmployeeMaster_Email").IsUnique();

            entity.HasIndex(e => e.EmployeeCode, "UQ_EmployeeMaster_EmployeeCode").IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.EmployeeCode).HasMaxLength(50);
            entity.Property(e => e.EmployeeName)
                .HasMaxLength(302)
                .HasComputedColumnSql("(concat_ws(' ',nullif(ltrim(rtrim([FirstName])),''),nullif(ltrim(rtrim([MiddleName])),''),nullif(ltrim(rtrim([LastName])),'')))", true);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LastLoginAt).HasColumnType("datetime");
            entity.Property(e => e.LastName).HasMaxLength(100);
            entity.Property(e => e.MiddleName).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.ProfileImageUrl).HasMaxLength(500);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithOne(p => p.EmployeeMaster)
                .HasForeignKey<EmployeeMaster>(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EmployeeMaster_CompanyMaster");

            entity.HasOne(d => d.Department).WithMany(p => p.EmployeeMasters)
                .HasForeignKey(d => d.DepartmentId)
                .HasConstraintName("FK_EmployeeMaster_DepartmentMaster");

            entity.HasOne(d => d.Designation).WithMany(p => p.EmployeeMasters)
                .HasForeignKey(d => d.DesignationId)
                .HasConstraintName("FK_EmployeeMaster_DesignationMaster");

            entity.HasOne(d => d.Role).WithMany(p => p.EmployeeMasters)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EmployeeMaster_RoleMaster");
        });

        modelBuilder.Entity<ErrorLog>(entity =>
        {
            entity.ToTable("ErrorLog");

            entity.HasIndex(e => e.CompanyId, "IX_ErrorLog_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_ErrorLog_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CreatedAt, "IX_ErrorLog_CreatedAt");

            entity.Property(e => e.CreatedAt).HasColumnType("datetime");
            entity.Property(e => e.ErrorMessage).IsRequired();
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Ipaddress).HasMaxLength(100);
            entity.Property(e => e.Method).HasMaxLength(50);
            entity.Property(e => e.Path).HasMaxLength(500);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.UserAgent).HasMaxLength(500);

            entity.HasOne(d => d.Company).WithMany(p => p.ErrorLogs)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_ErrorLog_CompanyMaster");

            entity.HasOne(d => d.Employee).WithMany(p => p.ErrorLogs)
                .HasForeignKey(d => d.EmployeeId)
                .HasConstraintName("FK_ErrorLog_EmployeeMaster");
        });

        modelBuilder.Entity<EnumCategory>(entity =>
        {
            entity.HasKey(e => e.EnumCategoryId);

            entity.ToTable("EnumCategory");

            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.CategoryName).HasMaxLength(200);
        });

        modelBuilder.Entity<EnumMaster>(entity =>
        {
            entity.HasKey(e => e.EnumId);

            entity.ToTable("EnumMaster");

            entity.HasIndex(e => e.EnumCategoryId, "IX_EnumMaster_EnumCategoryId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.EnumName).HasMaxLength(200);
            entity.Property(e => e.IsActive).HasDefaultValue(true);

            entity.HasOne(d => d.EnumCategory).WithMany(p => p.EnumMasters)
                .HasForeignKey(d => d.EnumCategoryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EnumMaster_EnumCategory");
        });

        modelBuilder.Entity<FollowUp>(entity =>
        {
            entity.ToTable("FollowUp");

            entity.HasIndex(e => e.AssignedTo, "IX_FollowUp_AssignedTo").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_FollowUp_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CustomerId, "IX_FollowUp_CustomerId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.LeadId, "IX_FollowUp_LeadId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.ScheduledDate, "IX_FollowUp_ScheduledDate_Pending").HasFilter("([Status]='Pending' AND [IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.Status }, "IX_FollowUp_Status").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CompletedDate).HasColumnType("datetime");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.ScheduledDate).HasColumnType("datetime");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasDefaultValue("Pending");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.AssignedToNavigation).WithMany(p => p.FollowUpAssignedToNavigations)
                .HasForeignKey(d => d.AssignedTo)
                .HasConstraintName("FK_FollowUp_AssignedTo");

            entity.HasOne(d => d.Company).WithMany(p => p.FollowUps)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_FollowUp_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.FollowUpCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_FollowUp_CreatedBy");

            entity.HasOne(d => d.Customer).WithMany(p => p.FollowUps)
                .HasForeignKey(d => d.CustomerId)
                .HasConstraintName("FK_FollowUp_CustomerMaster");

            entity.HasOne(d => d.Lead).WithMany(p => p.FollowUps)
                .HasForeignKey(d => d.LeadId)
                .HasConstraintName("FK_FollowUp_LeadMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.FollowUpUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_FollowUp_UpdatedBy");
        });

        modelBuilder.Entity<LeadMaster>(entity =>
        {
            entity.HasKey(e => e.LeadId);

            entity.ToTable("LeadMaster");

            entity.HasIndex(e => e.AssignedTo, "IX_LeadMaster_AssignedTo").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_LeadMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CreatedAt, "IX_LeadMaster_CreatedAt")
                .IsDescending()
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Email, "IX_LeadMaster_Email").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Phone, "IX_LeadMaster_Phone").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.Status }, "IX_LeadMaster_Status").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(200);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LastName).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Source).HasMaxLength(100);
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasDefaultValue("New");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.AssignedToNavigation).WithMany(p => p.LeadMasterAssignedToNavigations)
                .HasForeignKey(d => d.AssignedTo)
                .HasConstraintName("FK_LeadMaster_AssignedTo");

            entity.HasOne(d => d.Company).WithMany(p => p.LeadMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_LeadMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.LeadMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_LeadMaster_CreatedBy");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.LeadMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_LeadMaster_UpdatedBy");
        });

        modelBuilder.Entity<LoginHistory>(entity =>
        {
            entity.ToTable("LoginHistory");

            entity.HasIndex(e => e.CompanyId, "IX_LoginHistory_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_LoginHistory_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.LoginAt, "IX_LoginHistory_LoginAt")
                .IsDescending()
                .HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Status, "IX_LoginHistory_Status").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DeviceInfo).HasMaxLength(500);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.Ipaddress)
                .HasMaxLength(100)
                .HasColumnName("IPAddress");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LoginAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.LogoutAt).HasColumnType("datetime");
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.UserAgent).HasMaxLength(500);

            entity.HasOne(d => d.Company).WithMany(p => p.LoginHistories)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_LoginHistory_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.LoginHistoryCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_LoginHistory_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.LoginHistoryEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_LoginHistory_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.LoginHistoryUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_LoginHistory_UpdatedBy");
        });

        modelBuilder.Entity<MenuMaster>(entity =>
        {
            entity.HasKey(e => e.MenuId);

            entity.ToTable("MenuMaster");

            entity.HasIndex(e => e.CompanyId, "IX_MenuMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.ParentId, "IX_MenuMaster_ParentId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.ParentId, e.SortOrder }, "IX_MenuMaster_SortOrder").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.Icon).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.MenuName).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");
            entity.Property(e => e.Url).HasMaxLength(300);

            entity.HasOne(d => d.Company).WithMany(p => p.MenuMasters)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_MenuMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.MenuMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_MenuMaster_CreatedBy");

            entity.HasOne(d => d.Parent).WithMany(p => p.InverseParent)
                .HasForeignKey(d => d.ParentId)
                .HasConstraintName("FK_MenuMaster_ParentMenu");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.MenuMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_MenuMaster_UpdatedBy");
        });

        modelBuilder.Entity<NoteMaster>(entity =>
        {
            entity.HasKey(e => e.NoteId);

            entity.ToTable("NoteMaster");

            entity.HasIndex(e => e.CompanyId, "IX_NoteMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CustomerId, "IX_NoteMaster_CustomerId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.LeadId, "IX_NoteMaster_LeadId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.NoteMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_NoteMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.NoteMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_NoteMaster_CreatedBy");

            entity.HasOne(d => d.Customer).WithMany(p => p.NoteMasters)
                .HasForeignKey(d => d.CustomerId)
                .HasConstraintName("FK_NoteMaster_CustomerMaster");

            entity.HasOne(d => d.Lead).WithMany(p => p.NoteMasters)
                .HasForeignKey(d => d.LeadId)
                .HasConstraintName("FK_NoteMaster_LeadMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.NoteMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_NoteMaster_UpdatedBy");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.ToTable("Notification");

            entity.HasIndex(e => e.CompanyId, "IX_Notification_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_Notification_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.EmployeeId, e.IsRead }, "IX_Notification_EmployeeId_IsRead").HasFilter("([IsRead]=(0) AND [IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.Type }, "IX_Notification_Type").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.ReadAt).HasColumnType("datetime");
            entity.Property(e => e.SentAt).HasColumnType("datetime");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.Type)
                .HasMaxLength(50)
                .HasDefaultValue("InApp");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Notification_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.NotificationCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_Notification_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.NotificationEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Notification_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.NotificationUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_Notification_UpdatedBy");
        });

        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("RefreshToken");

            entity.HasIndex(e => e.CompanyId, "IX_RefreshToken_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_RefreshToken_EmployeeId").HasFilter("([IsActive]=(1) AND [IsRevoked]=(0))");

            entity.HasIndex(e => new { e.EmployeeId, e.IsRevoked }, "IX_RefreshToken_EmployeeId_IsRevoked").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.CreatedByIp).HasMaxLength(100);
            entity.Property(e => e.ExpiresAt).HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.RevokedAt).HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.RefreshTokens)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RefreshToken_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.RefreshTokenCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_RefreshToken_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.RefreshTokenEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RefreshToken_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.RefreshTokenUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_RefreshToken_UpdatedBy");
        });

        modelBuilder.Entity<RoleMaster>(entity =>
        {
            entity.HasKey(e => e.RoleId);

            entity.ToTable("RoleMaster");

            entity.HasIndex(e => e.CompanyId, "IX_RoleMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.RoleName }, "IX_RoleMaster_CompanyId_RoleName").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.RoleTypeId, "IX_RoleMaster_RoleTypeId").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.RoleName).HasMaxLength(100);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.RoleMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RoleMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.RoleMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_RoleMaster_CreatedBy");

            entity.HasOne(d => d.RoleType).WithMany(p => p.RoleMasters)
                .HasForeignKey(d => d.RoleTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RoleMaster_EnumMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.RoleMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_RoleMaster_UpdatedBy");
        });

        modelBuilder.Entity<RolePermission>(entity =>
        {
            entity.HasKey(e => e.PermissionId);

            entity.ToTable("RolePermission");

            entity.HasIndex(e => e.MenuId, "IX_RolePermission_MenuId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.RoleId, "IX_RolePermission_RoleId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.RoleId, e.MenuId }, "IX_RolePermission_RoleId_MenuId_Unique")
                .IsUnique()
                .HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.RolePermissionCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_RolePermission_CreatedBy");

            entity.HasOne(d => d.Menu).WithMany(p => p.RolePermissions)
                .HasForeignKey(d => d.MenuId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RolePermission_MenuMaster");

            entity.HasOne(d => d.Role).WithMany(p => p.RolePermissions)
                .HasForeignKey(d => d.RoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RolePermission_RoleMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.RolePermissionUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_RolePermission_UpdatedBy");
        });

        modelBuilder.Entity<TaskMaster>(entity =>
        {
            entity.HasKey(e => e.TaskId);

            entity.ToTable("TaskMaster");

            entity.HasIndex(e => e.AssignedTo, "IX_TaskMaster_AssignedTo").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CompanyId, "IX_TaskMaster_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.CustomerId, "IX_TaskMaster_CustomerId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DueDate, "IX_TaskMaster_DueDate_Pending").HasFilter("(([Status] IN ('Pending', 'InProgress')) AND [IsActive]=(1))");

            entity.HasIndex(e => e.LeadId, "IX_TaskMaster_LeadId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.Status }, "IX_TaskMaster_Status").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.CompletedDate).HasColumnType("datetime");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DueDate).HasColumnType("datetime");
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Priority)
                .HasMaxLength(50)
                .HasDefaultValue("Medium");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasDefaultValue("Pending");
            entity.Property(e => e.Title).HasMaxLength(200);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.AssignedToNavigation).WithMany(p => p.TaskMasterAssignedToNavigations)
                .HasForeignKey(d => d.AssignedTo)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TaskMaster_AssignedTo");

            entity.HasOne(d => d.Company).WithMany(p => p.TaskMasters)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_TaskMaster_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.TaskMasterCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_TaskMaster_CreatedBy");

            entity.HasOne(d => d.Customer).WithMany(p => p.TaskMasters)
                .HasForeignKey(d => d.CustomerId)
                .HasConstraintName("FK_TaskMaster_CustomerMaster");

            entity.HasOne(d => d.Lead).WithMany(p => p.TaskMasters)
                .HasForeignKey(d => d.LeadId)
                .HasConstraintName("FK_TaskMaster_LeadMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.TaskMasterUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_TaskMaster_UpdatedBy");
        });

        modelBuilder.Entity<UserDevice>(entity =>
        {
            entity.ToTable("UserDevice");

            entity.HasIndex(e => e.CompanyId, "IX_UserDevice_CompanyId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.DeviceId, "IX_UserDevice_DeviceId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.EmployeeId, "IX_UserDevice_EmployeeId").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.IsApproved }, "IX_UserDevice_IsApproved").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => new { e.CompanyId, e.IsOnline }, "IX_UserDevice_IsOnline").HasFilter("([IsActive]=(1))");

            entity.HasIndex(e => e.Status, "IX_UserDevice_Status").HasFilter("([IsActive]=(1))");

            entity.Property(e => e.AppVersion).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DeviceId).HasMaxLength(200);
            entity.Property(e => e.Guids).HasDefaultValueSql("(newid())");
            entity.Property(e => e.Imei)
                .HasMaxLength(100)
                .HasColumnName("IMEI");
            entity.Property(e => e.Ipaddress)
                .HasMaxLength(100)
                .HasColumnName("IPAddress");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.LastSyncAt).HasColumnType("datetime");
            entity.Property(e => e.Latitude).HasColumnType("decimal(10, 7)");
            entity.Property(e => e.Longitude).HasColumnType("decimal(10, 7)");
            entity.Property(e => e.Manufacturer).HasMaxLength(100);
            entity.Property(e => e.Model).HasMaxLength(100);
            entity.Property(e => e.Osversion)
                .HasMaxLength(100)
                .HasColumnName("OSVersion");
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.UpdatedAt).HasColumnType("datetime");

            entity.HasOne(d => d.Company).WithMany(p => p.UserDevices)
                .HasForeignKey(d => d.CompanyId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_UserDevice_CompanyMaster");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.UserDeviceCreatedByNavigations)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_UserDevice_CreatedBy");

            entity.HasOne(d => d.Employee).WithMany(p => p.UserDeviceEmployees)
                .HasForeignKey(d => d.EmployeeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_UserDevice_EmployeeMaster");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.UserDeviceUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK_UserDevice_UpdatedBy");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var auditEntries = OnBeforeSaveChanges();
        var result = await base.SaveChangesAsync(cancellationToken);
        await OnAfterSaveChangesAsync(auditEntries);
        return result;
    }

    private List<AuditEntry> OnBeforeSaveChanges()
    {
        ChangeTracker.DetectChanges();
        var auditEntries = new List<AuditEntry>();

        var employeeId = _currentUserService?.EmployeeId;
        var companyId = _currentUserService?.CompanyId;

        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.Entity is AuditLog || entry.Entity is ActivityLog || entry.Entity is ErrorLog || entry.State == EntityState.Detached || entry.State == EntityState.Unchanged)
                continue;

            var auditEntry = new AuditEntry(entry)
            {
                TableName = entry.Metadata.GetTableName() ?? entry.Entity.GetType().Name,
                EmployeeId = employeeId,
                CompanyId = companyId
            };
            auditEntries.Add(auditEntry);

            foreach (var property in entry.Properties)
            {
                if (property.IsTemporary)
                {
                    auditEntry.TemporaryProperties.Add(property);
                    continue;
                }

                string propertyName = property.Metadata.Name;
                if (property.Metadata.IsPrimaryKey())
                {
                    auditEntry.KeyValues[propertyName] = property.CurrentValue;
                    continue;
                }

                switch (entry.State)
                {
                    case EntityState.Added:
                        auditEntry.Action = "Insert";
                        auditEntry.NewValues[propertyName] = property.CurrentValue;
                        break;
                    case EntityState.Deleted:
                        auditEntry.Action = "Delete";
                        auditEntry.OldValues[propertyName] = property.OriginalValue;
                        break;
                    case EntityState.Modified:
                        if (property.IsModified)
                        {
                            auditEntry.Action = "Update";
                            auditEntry.OldValues[propertyName] = property.OriginalValue;
                            auditEntry.NewValues[propertyName] = property.CurrentValue;
                        }
                        break;
                }
            }
        }

        foreach (var auditEntry in auditEntries.Where(_ => !_.HasTemporaryProperties))
        {
            AuditLogs.Add(auditEntry.ToAuditLog());
        }

        return auditEntries.Where(_ => _.HasTemporaryProperties).ToList();
    }

    private Task OnAfterSaveChangesAsync(List<AuditEntry> auditEntries)
    {
        if (auditEntries == null || auditEntries.Count == 0)
            return Task.CompletedTask;

        foreach (var auditEntry in auditEntries)
        {
            foreach (var prop in auditEntry.TemporaryProperties)
            {
                if (prop.Metadata.IsPrimaryKey())
                {
                    auditEntry.KeyValues[prop.Metadata.Name] = prop.CurrentValue;
                }
                else
                {
                    auditEntry.NewValues[prop.Metadata.Name] = prop.CurrentValue;
                }
            }
            AuditLogs.Add(auditEntry.ToAuditLog());
        }

        return base.SaveChangesAsync();
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

public class AuditEntry
{
    public AuditEntry(Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry)
    {
        Entry = entry;
    }

    public Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry Entry { get; }
    public string TableName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public int? EmployeeId { get; set; }
    public int? CompanyId { get; set; }
    public Dictionary<string, object?> KeyValues { get; } = new Dictionary<string, object?>();
    public Dictionary<string, object?> OldValues { get; } = new Dictionary<string, object?>();
    public Dictionary<string, object?> NewValues { get; } = new Dictionary<string, object?>();
    public List<Microsoft.EntityFrameworkCore.ChangeTracking.PropertyEntry> TemporaryProperties { get; } = new List<Microsoft.EntityFrameworkCore.ChangeTracking.PropertyEntry>();

    public bool HasTemporaryProperties => TemporaryProperties.Any();

    public AuditLog ToAuditLog()
    {
        var recordIdStr = KeyValues.Values.FirstOrDefault()?.ToString();
        int? recordId = int.TryParse(recordIdStr, out var id) ? id : null;

        var audit = new AuditLog
        {
            CompanyId = CompanyId,
            EmployeeId = EmployeeId,
            TableName = TableName,
            Action = Action,
            Timestamp = DateTime.Now,
            RecordId = recordId,
            OldValues = OldValues.Count == 0 ? null : System.Text.Json.JsonSerializer.Serialize(OldValues),
            NewValues = NewValues.Count == 0 ? null : System.Text.Json.JsonSerializer.Serialize(NewValues)
        };
        return audit;
    }
}
