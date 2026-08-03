-- ====================================================
-- CALLMATRIX ERP + CRM - INDEX CREATION SCRIPTS
-- Regular Indexes + Filtered Indexes
-- ====================================================

USE [CallMatrixDB];
GO


-- ====================================================
-- COMPANY MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_CompanyMaster_CompanyCode]
    ON [dbo].[CompanyMaster]([CompanyCode])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CompanyMaster_IsActive]
    ON [dbo].[CompanyMaster]([IsActive])
    INCLUDE ([CompanyName], [CompanyCode]);
GO


-- ====================================================
-- BRANCH MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_BranchMaster_CompanyId]
    ON [dbo].[BranchMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_BranchMaster_BranchCode]
    ON [dbo].[BranchMaster]([BranchCode])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- DEPARTMENT MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_DepartmentMaster_CompanyId]
    ON [dbo].[DepartmentMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_DepartmentMaster_DepartmentCode]
    ON [dbo].[DepartmentMaster]([DepartmentCode])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- DESIGNATION MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_DesignationMaster_CompanyId]
    ON [dbo].[DesignationMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_DesignationMaster_DepartmentId]
    ON [dbo].[DesignationMaster]([DepartmentId])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- ENUM TYPE INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_EnumType_EnumId]
    ON [dbo].[EnumType]([EnumId])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- ROLE MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_RoleMaster_CompanyId]
    ON [dbo].[RoleMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_RoleMaster_RoleTypeId]
    ON [dbo].[RoleMaster]([RoleTypeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_RoleMaster_CompanyId_RoleName]
    ON [dbo].[RoleMaster]([CompanyId], [RoleName])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- EMPLOYEE MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_CompanyId]
    ON [dbo].[EmployeeMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_RoleId]
    ON [dbo].[EmployeeMaster]([RoleId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_DepartmentId]
    ON [dbo].[EmployeeMaster]([DepartmentId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_DesignationId]
    ON [dbo].[EmployeeMaster]([DesignationId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_Email]
    ON [dbo].[EmployeeMaster]([Email])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_EmployeeCode]
    ON [dbo].[EmployeeMaster]([EmployeeCode])
    WHERE [IsActive] = 1;
GO

-- CRITICAL: Filtered unique index ensuring only ONE active Tenant Owner per Company
CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployeeMaster_TenantOwner_Unique]
    ON [dbo].[EmployeeMaster]([CompanyId])
    WHERE [Tenant] = 1
    AND [IsActive] = 1;
GO

-- Filtered index for quick tenant owner lookup
CREATE NONCLUSTERED INDEX [IX_EmployeeMaster_Tenant]
    ON [dbo].[EmployeeMaster]([CompanyId], [Tenant])
    INCLUDE ([EmployeeId], [FirstName], [LastName], [Email])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- EMPLOYEE BRANCH INDEXES
-- ====================================================
-- Unique filtered index: No duplicate EmployeeId + BranchId for active records
CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployeeBranch_Employee_Branch_Unique]
    ON [dbo].[EmployeeBranch]([EmployeeId], [BranchId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeBranch_EmployeeId]
    ON [dbo].[EmployeeBranch]([EmployeeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_EmployeeBranch_BranchId]
    ON [dbo].[EmployeeBranch]([BranchId])
    WHERE [IsActive] = 1;
GO

-- Filtered index for primary branch lookup
CREATE NONCLUSTERED INDEX [IX_EmployeeBranch_PrimaryBranch]
    ON [dbo].[EmployeeBranch]([EmployeeId], [IsPrimaryBranch])
    WHERE [IsPrimaryBranch] = 1
    AND [IsActive] = 1;
GO


-- ====================================================
-- MENU MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_MenuMaster_CompanyId]
    ON [dbo].[MenuMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_MenuMaster_ParentId]
    ON [dbo].[MenuMaster]([ParentId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_MenuMaster_SortOrder]
    ON [dbo].[MenuMaster]([ParentId], [SortOrder])
    INCLUDE ([MenuName], [Icon], [Url])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- ROLE PERMISSION INDEXES
-- ====================================================
-- Unique filtered index: One permission entry per Role + Menu combo
CREATE UNIQUE NONCLUSTERED INDEX [IX_RolePermission_RoleId_MenuId_Unique]
    ON [dbo].[RolePermission]([RoleId], [MenuId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_RolePermission_RoleId]
    ON [dbo].[RolePermission]([RoleId])
    INCLUDE ([MenuId], [CanView], [CanAdd], [CanEdit], [CanDelete])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_RolePermission_MenuId]
    ON [dbo].[RolePermission]([MenuId])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- REFRESH TOKEN INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_RefreshToken_CompanyId]
    ON [dbo].[RefreshToken]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_RefreshToken_EmployeeId]
    ON [dbo].[RefreshToken]([EmployeeId])
    WHERE [IsActive] = 1 AND [IsRevoked] = 0;
GO

-- Performance index for token lookup during refresh
CREATE NONCLUSTERED INDEX [IX_RefreshToken_EmployeeId_IsRevoked]
    ON [dbo].[RefreshToken]([EmployeeId], [IsRevoked])
    INCLUDE ([Token], [ExpiresAt])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- LOGIN HISTORY INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_LoginHistory_CompanyId]
    ON [dbo].[LoginHistory]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LoginHistory_EmployeeId]
    ON [dbo].[LoginHistory]([EmployeeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LoginHistory_Status]
    ON [dbo].[LoginHistory]([Status])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LoginHistory_LoginAt]
    ON [dbo].[LoginHistory]([LoginAt] DESC)
    INCLUDE ([EmployeeId], [IPAddress], [Status])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- LEAD MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_LeadMaster_CompanyId]
    ON [dbo].[LeadMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LeadMaster_Status]
    ON [dbo].[LeadMaster]([CompanyId], [Status])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LeadMaster_AssignedTo]
    ON [dbo].[LeadMaster]([AssignedTo])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LeadMaster_Email]
    ON [dbo].[LeadMaster]([Email])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LeadMaster_Phone]
    ON [dbo].[LeadMaster]([Phone])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_LeadMaster_CreatedAt]
    ON [dbo].[LeadMaster]([CreatedAt] DESC)
    INCLUDE ([CompanyId], [FirstName], [LastName], [Status])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- CUSTOMER MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_CustomerMaster_CompanyId]
    ON [dbo].[CustomerMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CustomerMaster_LeadId]
    ON [dbo].[CustomerMaster]([LeadId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CustomerMaster_Email]
    ON [dbo].[CustomerMaster]([Email])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CustomerMaster_Phone]
    ON [dbo].[CustomerMaster]([Phone])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- CONTACT MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_ContactMaster_CompanyId]
    ON [dbo].[ContactMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_ContactMaster_CustomerId]
    ON [dbo].[ContactMaster]([CustomerId])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- FOLLOW UP INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_FollowUp_CompanyId]
    ON [dbo].[FollowUp]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_FollowUp_LeadId]
    ON [dbo].[FollowUp]([LeadId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_FollowUp_CustomerId]
    ON [dbo].[FollowUp]([CustomerId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_FollowUp_AssignedTo]
    ON [dbo].[FollowUp]([AssignedTo])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_FollowUp_Status]
    ON [dbo].[FollowUp]([CompanyId], [Status])
    WHERE [IsActive] = 1;
GO

-- Performance index for overdue follow-ups query
CREATE NONCLUSTERED INDEX [IX_FollowUp_ScheduledDate_Pending]
    ON [dbo].[FollowUp]([ScheduledDate])
    INCLUDE ([CompanyId], [LeadId], [CustomerId], [AssignedTo])
    WHERE [Status] = 'Pending'
    AND [IsActive] = 1;
GO


-- ====================================================
-- NOTE MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_NoteMaster_CompanyId]
    ON [dbo].[NoteMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_NoteMaster_LeadId]
    ON [dbo].[NoteMaster]([LeadId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_NoteMaster_CustomerId]
    ON [dbo].[NoteMaster]([CustomerId])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- TASK MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_TaskMaster_CompanyId]
    ON [dbo].[TaskMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_TaskMaster_AssignedTo]
    ON [dbo].[TaskMaster]([AssignedTo])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_TaskMaster_LeadId]
    ON [dbo].[TaskMaster]([LeadId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_TaskMaster_CustomerId]
    ON [dbo].[TaskMaster]([CustomerId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_TaskMaster_Status]
    ON [dbo].[TaskMaster]([CompanyId], [Status])
    WHERE [IsActive] = 1;
GO

-- Performance index for overdue tasks query
CREATE NONCLUSTERED INDEX [IX_TaskMaster_DueDate_Pending]
    ON [dbo].[TaskMaster]([DueDate])
    INCLUDE ([CompanyId], [Title], [AssignedTo], [Priority])
    WHERE [Status] IN ('Pending', 'InProgress')
    AND [IsActive] = 1;
GO


-- ====================================================
-- USER DEVICE INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_UserDevice_CompanyId]
    ON [dbo].[UserDevice]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_UserDevice_EmployeeId]
    ON [dbo].[UserDevice]([EmployeeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_UserDevice_DeviceId]
    ON [dbo].[UserDevice]([DeviceId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_UserDevice_IsApproved]
    ON [dbo].[UserDevice]([CompanyId], [IsApproved])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_UserDevice_IsOnline]
    ON [dbo].[UserDevice]([CompanyId], [IsOnline])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_UserDevice_Status]
    ON [dbo].[UserDevice]([Status])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- CALL MASTER INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_CallMaster_CompanyId]
    ON [dbo].[CallMaster]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallMaster_EmployeeId]
    ON [dbo].[CallMaster]([EmployeeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallMaster_PhoneNumber]
    ON [dbo].[CallMaster]([PhoneNumber])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallMaster_CallType]
    ON [dbo].[CallMaster]([CompanyId], [CallType])
    WHERE [IsActive] = 1;
GO

-- High-performance index for call analytics date-range queries
CREATE NONCLUSTERED INDEX [IX_CallMaster_CallDateTime]
    ON [dbo].[CallMaster]([CallDateTime] DESC)
    INCLUDE ([CompanyId], [EmployeeId], [CallType], [Duration], [PhoneNumber])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallMaster_DeviceId]
    ON [dbo].[CallMaster]([DeviceId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallMaster_CustomerId]
    ON [dbo].[CallMaster]([CustomerId])
    WHERE [IsActive] = 1;
GO

-- Composite index for employee call analytics
CREATE NONCLUSTERED INDEX [IX_CallMaster_CompanyId_EmployeeId_CallDateTime]
    ON [dbo].[CallMaster]([CompanyId], [EmployeeId], [CallDateTime] DESC)
    INCLUDE ([CallType], [Duration])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- CALL RECORDING INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_CallRecording_CompanyId]
    ON [dbo].[CallRecording]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallRecording_CallId]
    ON [dbo].[CallRecording]([CallId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_CallRecording_UploadStatus]
    ON [dbo].[CallRecording]([CompanyId], [UploadStatus])
    WHERE [IsActive] = 1;
GO

-- Performance index for pending uploads
CREATE NONCLUSTERED INDEX [IX_CallRecording_PendingUploads]
    ON [dbo].[CallRecording]([UploadStatus])
    INCLUDE ([CallId], [FileName], [CompanyId])
    WHERE [UploadStatus] IN ('Pending', 'Failed')
    AND [IsActive] = 1;
GO


-- ====================================================
-- NOTIFICATION INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_Notification_CompanyId]
    ON [dbo].[Notification]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_Notification_EmployeeId]
    ON [dbo].[Notification]([EmployeeId])
    WHERE [IsActive] = 1;
GO

-- Performance index for unread notifications
CREATE NONCLUSTERED INDEX [IX_Notification_EmployeeId_IsRead]
    ON [dbo].[Notification]([EmployeeId], [IsRead])
    INCLUDE ([Title], [Message], [Type], [SentAt])
    WHERE [IsRead] = 0
    AND [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_Notification_Type]
    ON [dbo].[Notification]([CompanyId], [Type])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- ACTIVITY LOG INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_ActivityLog_CompanyId]
    ON [dbo].[ActivityLog]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_ActivityLog_EmployeeId]
    ON [dbo].[ActivityLog]([EmployeeId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_ActivityLog_EntityType_EntityId]
    ON [dbo].[ActivityLog]([EntityType], [EntityId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_ActivityLog_CreatedAt]
    ON [dbo].[ActivityLog]([CreatedAt] DESC)
    INCLUDE ([CompanyId], [EmployeeId], [Action], [EntityType])
    WHERE [IsActive] = 1;
GO


-- ====================================================
-- AUDIT LOG INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_AuditLog_CompanyId]
    ON [dbo].[AuditLog]([CompanyId]);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLog_EmployeeId]
    ON [dbo].[AuditLog]([EmployeeId]);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLog_TableName_RecordId]
    ON [dbo].[AuditLog]([TableName], [RecordId]);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLog_Timestamp]
    ON [dbo].[AuditLog]([Timestamp] DESC)
    INCLUDE ([TableName], [Action], [EmployeeId]);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLog_Action]
    ON [dbo].[AuditLog]([Action]);
GO


-- ====================================================
-- APP SETTINGS INDEXES
-- ====================================================
CREATE NONCLUSTERED INDEX [IX_AppSettings_CompanyId]
    ON [dbo].[AppSettings]([CompanyId])
    WHERE [IsActive] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_AppSettings_SettingKey]
    ON [dbo].[AppSettings]([CompanyId], [SettingKey])
    WHERE [IsActive] = 1;
GO


PRINT '';
PRINT '====================================================';
PRINT 'All indexes created successfully.';
PRINT '====================================================';
GO
