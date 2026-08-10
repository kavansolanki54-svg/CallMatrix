-- ====================================================
-- CALLALYZE ERP + CRM - AUDIT FOREIGN KEY SCRIPTS
-- CreatedBy / UpdatedBy → EmployeeMaster(EmployeeId)
-- ====================================================
-- 
-- RULE:
-- CreatedBy and UpdatedBy store EmployeeId (the logged-in user).
-- Every table gets FK references to EmployeeMaster EXCEPT:
--   EmployeeMaster itself (self-referencing exception)
--
-- ====================================================

USE [CallalyzeDB];
GO


-- ====================================================
-- COMPANY MASTER
-- ====================================================
ALTER TABLE [dbo].[CompanyMaster]
    ADD CONSTRAINT [FK_CompanyMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[CompanyMaster]
    ADD CONSTRAINT [FK_CompanyMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- BRANCH MASTER
-- ====================================================
ALTER TABLE [dbo].[BranchMaster]
    ADD CONSTRAINT [FK_BranchMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[BranchMaster]
    ADD CONSTRAINT [FK_BranchMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- DEPARTMENT MASTER
-- ====================================================
ALTER TABLE [dbo].[DepartmentMaster]
    ADD CONSTRAINT [FK_DepartmentMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[DepartmentMaster]
    ADD CONSTRAINT [FK_DepartmentMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- DESIGNATION MASTER
-- ====================================================
ALTER TABLE [dbo].[DesignationMaster]
    ADD CONSTRAINT [FK_DesignationMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[DesignationMaster]
    ADD CONSTRAINT [FK_DesignationMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- ROLE MASTER
-- ====================================================
ALTER TABLE [dbo].[RoleMaster]
    ADD CONSTRAINT [FK_RoleMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[RoleMaster]
    ADD CONSTRAINT [FK_RoleMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- EMPLOYEE MASTER
-- ====================================================
-- EXCEPTION: No FK on CreatedBy/UpdatedBy for EmployeeMaster
-- because EmployeeMaster references itself (circular dependency).
-- EmployeeMaster.CreatedBy and EmployeeMaster.UpdatedBy remain
-- as INT NULL without foreign key constraints.
-- ====================================================


-- ====================================================
-- EMPLOYEE BRANCH
-- ====================================================
ALTER TABLE [dbo].[EmployeeBranch]
    ADD CONSTRAINT [FK_EmployeeBranch_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[EmployeeBranch]
    ADD CONSTRAINT [FK_EmployeeBranch_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- MENU MASTER
-- ====================================================
ALTER TABLE [dbo].[MenuMaster]
    ADD CONSTRAINT [FK_MenuMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[MenuMaster]
    ADD CONSTRAINT [FK_MenuMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- ROLE PERMISSION
-- ====================================================
ALTER TABLE [dbo].[RolePermission]
    ADD CONSTRAINT [FK_RolePermission_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[RolePermission]
    ADD CONSTRAINT [FK_RolePermission_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- REFRESH TOKEN
-- ====================================================
ALTER TABLE [dbo].[RefreshToken]
    ADD CONSTRAINT [FK_RefreshToken_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[RefreshToken]
    ADD CONSTRAINT [FK_RefreshToken_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- LOGIN HISTORY
-- ====================================================
ALTER TABLE [dbo].[LoginHistory]
    ADD CONSTRAINT [FK_LoginHistory_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[LoginHistory]
    ADD CONSTRAINT [FK_LoginHistory_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- LEAD MASTER
-- ====================================================
ALTER TABLE [dbo].[LeadMaster]
    ADD CONSTRAINT [FK_LeadMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[LeadMaster]
    ADD CONSTRAINT [FK_LeadMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- CUSTOMER MASTER
-- ====================================================
ALTER TABLE [dbo].[CustomerMaster]
    ADD CONSTRAINT [FK_CustomerMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[CustomerMaster]
    ADD CONSTRAINT [FK_CustomerMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- CONTACT MASTER
-- ====================================================
ALTER TABLE [dbo].[ContactMaster]
    ADD CONSTRAINT [FK_ContactMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[ContactMaster]
    ADD CONSTRAINT [FK_ContactMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- FOLLOW UP
-- ====================================================
ALTER TABLE [dbo].[FollowUp]
    ADD CONSTRAINT [FK_FollowUp_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[FollowUp]
    ADD CONSTRAINT [FK_FollowUp_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- NOTE MASTER
-- ====================================================
ALTER TABLE [dbo].[NoteMaster]
    ADD CONSTRAINT [FK_NoteMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[NoteMaster]
    ADD CONSTRAINT [FK_NoteMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- TASK MASTER
-- ====================================================
ALTER TABLE [dbo].[TaskMaster]
    ADD CONSTRAINT [FK_TaskMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[TaskMaster]
    ADD CONSTRAINT [FK_TaskMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- USER DEVICE
-- ====================================================
ALTER TABLE [dbo].[UserDevice]
    ADD CONSTRAINT [FK_UserDevice_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[UserDevice]
    ADD CONSTRAINT [FK_UserDevice_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- CALL MASTER
-- ====================================================
ALTER TABLE [dbo].[CallMaster]
    ADD CONSTRAINT [FK_CallMaster_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[CallMaster]
    ADD CONSTRAINT [FK_CallMaster_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- CALL RECORDING
-- ====================================================
ALTER TABLE [dbo].[CallRecording]
    ADD CONSTRAINT [FK_CallRecording_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[CallRecording]
    ADD CONSTRAINT [FK_CallRecording_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- NOTIFICATION
-- ====================================================
ALTER TABLE [dbo].[Notification]
    ADD CONSTRAINT [FK_Notification_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[Notification]
    ADD CONSTRAINT [FK_Notification_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- ACTIVITY LOG
-- ====================================================
ALTER TABLE [dbo].[ActivityLog]
    ADD CONSTRAINT [FK_ActivityLog_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[ActivityLog]
    ADD CONSTRAINT [FK_ActivityLog_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- APP SETTINGS
-- ====================================================
ALTER TABLE [dbo].[AppSettings]
    ADD CONSTRAINT [FK_AppSettings_CreatedBy] FOREIGN KEY ([CreatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO

ALTER TABLE [dbo].[AppSettings]
    ADD CONSTRAINT [FK_AppSettings_UpdatedBy] FOREIGN KEY ([UpdatedBy])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]);
GO


-- ====================================================
-- NOTE: AuditLog does NOT get CreatedBy/UpdatedBy FKs
-- because AuditLog already has its own EmployeeId FK
-- and does not follow the standard audit column pattern.
-- ====================================================


PRINT '';
PRINT '====================================================';
PRINT 'All audit foreign keys created successfully.';
PRINT 'Exception: EmployeeMaster (self-referencing - no FK)';
PRINT 'Exception: AuditLog (uses EmployeeId directly)';
PRINT '====================================================';
GO
