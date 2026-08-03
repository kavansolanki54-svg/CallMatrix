-- ====================================================
-- CALLMATRIX ERP + CRM - ALTER SCRIPT
-- Applies updates to an existing database:
-- 1. Drops ModuleCode column and constraint from MenuMaster
-- 2. Removes IX_MenuMaster_ModuleCode index
-- 3. Deletes 'Dashboard' menu entry (if exists) and cleans up references
-- ====================================================

USE [CallMatrixDB];
GO

PRINT 'Starting database migration/alter script...';
GO

-- ====================================================
-- 1. DROP INDEXES AND CONSTRAINTS DEPENDENT ON ModuleCode
-- ====================================================

-- Drop IX_MenuMaster_ModuleCode index if it exists
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_MenuMaster_ModuleCode' AND object_id = OBJECT_ID(N'[dbo].[MenuMaster]'))
BEGIN
    DROP INDEX [IX_MenuMaster_ModuleCode] ON [dbo].[MenuMaster];
    PRINT 'Dropped index [IX_MenuMaster_ModuleCode].';
END
GO

-- Drop UQ_MenuMaster_ModuleCode constraint if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE name = N'UQ_MenuMaster_ModuleCode' AND type = 'UQ')
BEGIN
    ALTER TABLE [dbo].[MenuMaster] DROP CONSTRAINT [UQ_MenuMaster_ModuleCode];
    PRINT 'Dropped unique constraint [UQ_MenuMaster_ModuleCode].';
END
GO

-- Recreate IX_MenuMaster_SortOrder index without ModuleCode column
IF EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_MenuMaster_SortOrder' AND object_id = OBJECT_ID(N'[dbo].[MenuMaster]'))
BEGIN
    DROP INDEX [IX_MenuMaster_SortOrder] ON [dbo].[MenuMaster];
END

CREATE NONCLUSTERED INDEX [IX_MenuMaster_SortOrder]
    ON [dbo].[MenuMaster]([ParentId], [SortOrder])
    INCLUDE ([MenuName], [Icon], [Url])
    WHERE [IsActive] = 1;
PRINT 'Recreated index [IX_MenuMaster_SortOrder] without ModuleCode.';
GO


-- ====================================================
-- 2. DROP COLUMN ModuleCode FROM MenuMaster
-- ====================================================

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[MenuMaster]') AND name = N'ModuleCode')
BEGIN
    ALTER TABLE [dbo].[MenuMaster] DROP COLUMN [ModuleCode];
    PRINT 'Dropped column [ModuleCode] from [dbo].[MenuMaster].';
END
ELSE
BEGIN
    PRINT 'Column [ModuleCode] does not exist in [dbo].[MenuMaster].';
END
GO


-- ====================================================
-- 3. REMOVE DASHBOARD MENU AND CLEAN UP PERMISSIONS
-- ====================================================

-- Delete role permissions associated with Dashboard menu (MenuName = 'Dashboard' or MenuId = 1)
DELETE FROM [dbo].[RolePermission]
WHERE [MenuId] IN (SELECT [MenuId] FROM [dbo].[MenuMaster] WHERE [MenuName] = N'Dashboard' OR [MenuId] = 1);
PRINT 'Deleted RolePermissions for Dashboard menu.';
GO

-- Delete Dashboard menu entry
DELETE FROM [dbo].[MenuMaster]
WHERE [MenuName] = N'Dashboard' OR [MenuId] = 1;
PRINT 'Deleted Dashboard menu entry from MenuMaster.';
GO


PRINT '';
PRINT '====================================================';
PRINT 'Alter script completed successfully.';
PRINT '====================================================';
GO
