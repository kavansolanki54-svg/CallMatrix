-- ====================================================
-- SEED DATA: MenuMaster Hierarchy
-- ====================================================

-- Clear existing menus
DELETE FROM [dbo].[MenuMaster];
DBCC CHECKIDENT ('[dbo].[MenuMaster]', RESEED, 0);

DECLARE @HomeId INT, @AdminId INT, @MasterId INT, @CrmId INT, @CallDeviceId INT, @ReportsId INT, @SettingsId INT;

-- 1. Home
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Home', 'Grid', '/', NULL, 1, 1, GETDATE(), 1);
SET @HomeId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Company', 'Page', '/settings', @HomeId, 1, 1, GETDATE(), 1);

-- 2. Administrative
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Administrative', 'List', NULL, NULL, 2, 1, GETDATE(), 1);
SET @AdminId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Role Master', 'UserCircle', '/roles', @AdminId, 1, 1, GETDATE(), 1);
    
    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Access Control', 'BoxCube', '/roles', @AdminId, 2, 1, GETDATE(), 1);
    
    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Menus Master', 'ListTree', '/menus', @AdminId, 3, 1, GETDATE(), 1);

-- 3. Master
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Master', 'BoxCube', NULL, NULL, 3, 1, GETDATE(), 1);
SET @MasterId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Department', 'Grid', '/departments', @MasterId, 1, 1, GETDATE(), 1);
    
    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Designation', 'Grid', '/designations', @MasterId, 2, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Branch', 'Grid', '/branches', @MasterId, 3, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Employee', 'UserCircle', '/employees', @MasterId, 4, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Notification', 'Grid', '/notifications', @MasterId, 5, 1, GETDATE(), 1);

-- 4. CRM
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'CRM', 'UserCircle', NULL, NULL, 4, 1, GETDATE(), 1);
SET @CrmId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Lead', 'Grid', '/leads', @CrmId, 1, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Customer', 'UserCircle', '/customers', @CrmId, 2, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Contact', 'Grid', '/contacts', @CrmId, 3, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Follow Up', 'Grid', '/followups', @CrmId, 4, 1, GETDATE(), 1);
    
    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Task', 'Grid', '/tasks', @CrmId, 5, 1, GETDATE(), 1);

-- 5. Call & Device Management
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Call & Device Management', 'PieChart', NULL, NULL, 5, 1, GETDATE(), 1);
SET @CallDeviceId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Device Management', 'BoxCube', '/devices', @CallDeviceId, 1, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Call Logs', 'PieChart', '/calls', @CallDeviceId, 2, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Call Recordings', 'PieChart', '/recordings', @CallDeviceId, 3, 1, GETDATE(), 1);

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Call Analytics', 'PieChart', '/analytics', @CallDeviceId, 4, 1, GETDATE(), 1);

-- 6. Reports
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Reports', 'Table', NULL, NULL, 6, 1, GETDATE(), 1);
SET @ReportsId = SCOPE_IDENTITY();

    INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
    VALUES (NULL, 'Sub Reports', 'Table', '/reports', @ReportsId, 1, 1, GETDATE(), 1);

-- 7. Settings
INSERT INTO [dbo].[MenuMaster] (CompanyId, MenuName, Icon, Url, ParentId, SortOrder, IsActive, CreatedAt, CreatedBy)
VALUES (NULL, 'Settings', 'Page', '/settings', NULL, 7, 1, GETDATE(), 1);
SET @SettingsId = SCOPE_IDENTITY();


PRINT 'Menus Seeded Successfully.';
