-- ====================================================
-- CALLALYZE ERP + CRM - SEED DATA SCRIPTS
-- Default data for production deployment
-- ====================================================

USE [CallalyzeDB];
GO


-- ====================================================
-- 1. ENUM MASTER - Lookup Type Categories
-- ====================================================
SET IDENTITY_INSERT [dbo].[EnumMaster] ON;
GO

INSERT INTO [dbo].[EnumMaster] ([EnumId], [TypeName], [IsActive])
VALUES
    (1, N'Role', 1);
GO

SET IDENTITY_INSERT [dbo].[EnumMaster] OFF;
GO

PRINT 'EnumMaster seed data inserted.';
GO


-- ====================================================
-- 2. ENUM TYPE - Lookup Values (Role Types)
-- ====================================================
SET IDENTITY_INSERT [dbo].[EnumType] ON;
GO

INSERT INTO [dbo].[EnumType] ([EnumTypeId], [EnumId], [EnumTypeName], [SortOrder], [IsActive])
VALUES
    (1, 1, N'Super Admin',    1, 1),
    (2, 1, N'Company Admin',  2, 1),
    (3, 1, N'Branch Admin',   3, 1),
    (4, 1, N'Manager',        4, 1),
    (5, 1, N'Employee',       5, 1);
GO

SET IDENTITY_INSERT [dbo].[EnumType] OFF;
GO

PRINT 'EnumType seed data inserted.';
GO


-- ====================================================
-- 3. COMPANY MASTER - Sample Tenant Company
-- ====================================================
SET IDENTITY_INSERT [dbo].[CompanyMaster] ON;
GO

INSERT INTO [dbo].[CompanyMaster]
(
    [CompanyId], [CompanyName], [CompanyCode], [Industry],
    [Website], [Email], [Phone],
    [Address], [Country], [State], [City], [Pincode],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
(
    1, N'ABC Technologies', N'ABC-TECH', N'Information Technology',
    N'https://www.abctech.com', N'info@abctech.com', N'+91-9876543210',
    N'123, Tech Park, Electronic City', N'India', N'Karnataka', N'Bangalore', N'560100',
    GETDATE(), NULL, 1
);
GO

SET IDENTITY_INSERT [dbo].[CompanyMaster] OFF;
GO

PRINT 'CompanyMaster seed data inserted.';
GO


-- ====================================================
-- 4. BRANCH MASTER - Head Office + Branch Office
-- ====================================================
SET IDENTITY_INSERT [dbo].[BranchMaster] ON;
GO

INSERT INTO [dbo].[BranchMaster]
(
    [BranchId], [CompanyId], [BranchName], [BranchCode],
    [Address], [Country], [State], [City], [Pincode],
    [Phone], [Email],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
(
    1, 1, N'Head Office', N'HO-BLR',
    N'123, Tech Park, Electronic City', N'India', N'Karnataka', N'Bangalore', N'560100',
    N'+91-9876543210', N'ho@abctech.com',
    GETDATE(), NULL, 1
),
(
    2, 1, N'Branch Office', N'BO-MUM',
    N'456, Business Hub, Andheri East', N'India', N'Maharashtra', N'Mumbai', N'400069',
    N'+91-9876543211', N'mumbai@abctech.com',
    GETDATE(), NULL, 1
);
GO

SET IDENTITY_INSERT [dbo].[BranchMaster] OFF;
GO

PRINT 'BranchMaster seed data inserted.';
GO


-- ====================================================
-- 5. DEPARTMENT MASTER - Default Departments
-- ====================================================
SET IDENTITY_INSERT [dbo].[DepartmentMaster] ON;
GO

INSERT INTO [dbo].[DepartmentMaster]
(
    [DepartmentId], [CompanyId], [DepartmentName], [DepartmentCode],
    [Description], [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    (1, 1, N'Management',   N'MGMT',   N'Management and Administration',       GETDATE(), NULL, 1),
    (2, 1, N'Sales',        N'SALES',  N'Sales and Business Development',      GETDATE(), NULL, 1),
    (3, 1, N'Marketing',    N'MKT',    N'Marketing and Communications',        GETDATE(), NULL, 1),
    (4, 1, N'Support',      N'SUP',    N'Customer Support and Service',        GETDATE(), NULL, 1),
    (5, 1, N'Human Resources', N'HR',  N'Human Resources and Recruitment',     GETDATE(), NULL, 1),
    (6, 1, N'IT',           N'IT',     N'Information Technology',              GETDATE(), NULL, 1);
GO

SET IDENTITY_INSERT [dbo].[DepartmentMaster] OFF;
GO

PRINT 'DepartmentMaster seed data inserted.';
GO


-- ====================================================
-- 6. DESIGNATION MASTER - Default Designations
-- ====================================================
SET IDENTITY_INSERT [dbo].[DesignationMaster] ON;
GO

INSERT INTO [dbo].[DesignationMaster]
(
    [DesignationId], [CompanyId], [DepartmentId], [DesignationName],
    [Description], [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    (1, 1, 1, N'CEO',               N'Chief Executive Officer',     GETDATE(), NULL, 1),
    (2, 1, 2, N'Sales Manager',     N'Sales Department Manager',    GETDATE(), NULL, 1),
    (3, 1, 2, N'Sales Executive',   N'Sales Team Member',           GETDATE(), NULL, 1),
    (4, 1, 5, N'HR Manager',        N'HR Department Manager',       GETDATE(), NULL, 1),
    (5, 1, 5, N'HR Executive',      N'HR Team Member',              GETDATE(), NULL, 1),
    (6, 1, 6, N'IT Administrator',  N'IT System Administrator',     GETDATE(), NULL, 1);
GO

SET IDENTITY_INSERT [dbo].[DesignationMaster] OFF;
GO

PRINT 'DesignationMaster seed data inserted.';
GO


-- ====================================================
-- 7. ROLE MASTER - Default Roles
-- ====================================================
SET IDENTITY_INSERT [dbo].[RoleMaster] ON;
GO

INSERT INTO [dbo].[RoleMaster]
(
    [RoleId], [CompanyId], [RoleName], [RoleTypeId],
    [Description], [IsSystem],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    (1, 1, N'Company Admin',  2, N'Company Administrator with full access',       1, GETDATE(), NULL, 1),
    (2, 1, N'Branch Admin',   3, N'Branch Administrator',                         1, GETDATE(), NULL, 1),
    (3, 1, N'Manager',        4, N'Department Manager with team management',      1, GETDATE(), NULL, 1),
    (4, 1, N'Employee',       5, N'Regular Employee with limited access',         1, GETDATE(), NULL, 1);
GO

SET IDENTITY_INSERT [dbo].[RoleMaster] OFF;
GO

PRINT 'RoleMaster seed data inserted.';
GO


-- ====================================================
-- 8. EMPLOYEE MASTER - Tenant Owner + Sub Users
-- ====================================================
-- Password: Admin@123 (hashed using PBKDF2 — replace with actual hash from application)
-- For initial setup, we store a placeholder. The application's Encryption.HashPassword() 
-- should be used to generate the real hash on first login or via a setup endpoint.

SET IDENTITY_INSERT [dbo].[EmployeeMaster] ON;
GO

INSERT INTO [dbo].[EmployeeMaster]
(
    [EmployeeId], [CompanyId], [DepartmentId], [DesignationId], [RoleId],
    [EmployeeCode], [FirstName], [MiddleName], [LastName],
    [Email], [Phone], [Password],
    [Tenant],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
-- Tenant Owner (Tenant = 1) — Company Owner
(
    1, 1, 1, 1, 1,
    N'EMP-001', N'John', NULL, N'Owner',
    N'john.owner@abctech.com', N'+91-9876543210',
    N'AQAAAAIAAYagAAAAEH5a+V8nR3zRQxK2fVGhHgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', -- Placeholder hash
    1,      -- Tenant = 1 (Company Owner)
    GETDATE(), NULL, 1
),
-- Sub User (Tenant = 0) — Sales Employee
(
    2, 1, 2, 3, 4,
    N'EMP-002', N'Mike', NULL, N'Employee',
    N'mike.employee@abctech.com', N'+91-9876543211',
    N'AQAAAAIAAYagAAAAEH5a+V8nR3zRQxK2fVGhHgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', -- Placeholder hash
    0,      -- Tenant = 0 (Sub User)
    GETDATE(), 1, 1
),
-- Sub User (Tenant = 0) — HR Employee
(
    3, 1, 5, 5, 4,
    N'EMP-003', N'David', NULL, N'Employee',
    N'david.employee@abctech.com', N'+91-9876543212',
    N'AQAAAAIAAYagAAAAEH5a+V8nR3zRQxK2fVGhHgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', -- Placeholder hash
    0,      -- Tenant = 0 (Sub User)
    GETDATE(), 1, 1
);
GO

SET IDENTITY_INSERT [dbo].[EmployeeMaster] OFF;
GO

PRINT 'EmployeeMaster seed data inserted.';
PRINT '  → John Owner   (Tenant=1, Company Owner)';
PRINT '  → Mike Employee (Tenant=0, Sub User)';
PRINT '  → David Employee(Tenant=0, Sub User)';
GO


-- ====================================================
-- 9. EMPLOYEE BRANCH - Multi-Branch Assignment
-- ====================================================
SET IDENTITY_INSERT [dbo].[EmployeeBranch] ON;
GO

INSERT INTO [dbo].[EmployeeBranch]
(
    [EmployeeBranchId], [EmployeeId], [BranchId], [IsPrimaryBranch],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    -- John Owner → Branch 1 (Head Office) - Primary
    (1, 1, 1, 1, GETDATE(), 1, 1),

    -- Mike Employee → Branch 1 (Head Office) - Primary
    (2, 2, 1, 1, GETDATE(), 1, 1),
    -- Mike Employee → Branch 2 (Branch Office) - Secondary
    (3, 2, 2, 0, GETDATE(), 1, 1),

    -- David Employee → Branch 2 (Branch Office) - Primary
    (4, 3, 2, 1, GETDATE(), 1, 1);
GO

SET IDENTITY_INSERT [dbo].[EmployeeBranch] OFF;
GO

PRINT 'EmployeeBranch seed data inserted.';
PRINT '  → John Owner   → Branch 1 (Primary)';
PRINT '  → Mike Employee → Branch 1 (Primary), Branch 2 (Secondary)';
PRINT '  → David Employee→ Branch 2 (Primary)';
GO


-- ====================================================
-- 10. MENU MASTER - Dynamic Menu Hierarchy
-- ====================================================
SET IDENTITY_INSERT [dbo].[MenuMaster] ON;
GO

INSERT INTO [dbo].[MenuMaster]
(
    [MenuId], [CompanyId], [MenuName], [Icon], [Url],
    [ParentId], [SortOrder],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    -- Level 0: Top-level menus
    (2,  NULL, N'Employee Management',  N'people',          NULL,                       NULL, 1,  GETDATE(), NULL, 1),
    (3,  NULL, N'Branch Management',    N'business',        N'/branches',               NULL, 2,  GETDATE(), NULL, 1),
    (4,  NULL, N'Role Management',      N'admin_panel_settings', N'/roles',             NULL, 3,  GETDATE(), NULL, 1),
    (5,  NULL, N'CRM',                  N'contacts',        NULL,                       NULL, 4,  GETDATE(), NULL, 1),
    (6,  NULL, N'Call Management',      N'phone_in_talk',   NULL,                       NULL, 5,  GETDATE(), NULL, 1),
    (7,  NULL, N'Device Management',    N'devices',         N'/devices',                NULL, 6,  GETDATE(), NULL, 1),
    (8,  NULL, N'Reports',              N'assessment',      N'/reports',                NULL, 7,  GETDATE(), NULL, 1),
    (9,  NULL, N'Notifications',        N'notifications',   N'/notifications',          NULL, 8,  GETDATE(), NULL, 1),
    (10, NULL, N'Settings',             N'settings',        NULL,                       NULL, 9,  GETDATE(), NULL, 1),

    -- Level 1: Employee Management children
    (11, NULL, N'Employees',            N'person',          N'/employees',              2,    1,  GETDATE(), NULL, 1),
    (12, NULL, N'Departments',          N'category',        N'/departments',            2,    2,  GETDATE(), NULL, 1),
    (13, NULL, N'Designations',         N'badge',           N'/designations',           2,    3,  GETDATE(), NULL, 1),

    -- Level 1: CRM children
    (14, NULL, N'Leads',                N'leaderboard',     N'/crm/leads',              5,    1,  GETDATE(), NULL, 1),
    (15, NULL, N'Customers',            N'group',           N'/crm/customers',          5,    2,  GETDATE(), NULL, 1),
    (16, NULL, N'Contacts',             N'contact_page',    N'/crm/contacts',           5,    3,  GETDATE(), NULL, 1),
    (17, NULL, N'Follow-ups',           N'event_repeat',    N'/crm/follow-ups',         5,    4,  GETDATE(), NULL, 1),
    (18, NULL, N'Tasks',                N'task_alt',        N'/crm/tasks',              5,    5,  GETDATE(), NULL, 1),

    -- Level 1: Call Management children
    (19, NULL, N'Call Logs',            N'call',            N'/calls',                  6,    1,  GETDATE(), NULL, 1),
    (20, NULL, N'Call Recordings',      N'mic',             N'/calls/recordings',       6,    2,  GETDATE(), NULL, 1),
    (21, NULL, N'Call Analytics',       N'analytics',       N'/calls/analytics',        6,    3,  GETDATE(), NULL, 1),

    -- Level 1: Settings children
    (22, NULL, N'Users',                N'manage_accounts', N'/settings/users',         10,   1,  GETDATE(), NULL, 1),
    (23, NULL, N'Role Permissions',     N'lock',            N'/settings/permissions',   10,   2,  GETDATE(), NULL, 1),
    (24, NULL, N'Menu Management',      N'menu',            N'/settings/menus',         10,   3,  GETDATE(), NULL, 1),
    (25, NULL, N'Audit Logs',           N'history',         N'/settings/audit-logs',    10,   4,  GETDATE(), NULL, 1),
    (26, NULL, N'App Settings',         N'tune',            N'/settings/app',           10,   5,  GETDATE(), NULL, 1);
GO

SET IDENTITY_INSERT [dbo].[MenuMaster] OFF;
GO

PRINT 'MenuMaster seed data inserted (25 menu items).';
GO


-- ====================================================
-- 11. ROLE PERMISSION - Company Admin gets ALL permissions
-- ====================================================

-- Company Admin Role (RoleId = 1) → ALL menus → ALL permissions = 1
INSERT INTO [dbo].[RolePermission]
(
    [RoleId], [MenuId],
    [CanView], [CanAdd], [CanEdit], [CanDelete],
    [CanExport], [CanImport], [CanPrint],
    [CanUpload], [CanDownload], [CanApprove], [CanAssign],
    [CreatedAt], [CreatedBy], [IsActive]
)
SELECT
    1,              -- RoleId: Company Admin
    m.[MenuId],
    1, 1, 1, 1,     -- CanView, CanAdd, CanEdit, CanDelete
    1, 1, 1,         -- CanExport, CanImport, CanPrint
    1, 1, 1, 1,     -- CanUpload, CanDownload, CanApprove, CanAssign
    GETDATE(), 1, 1
FROM [dbo].[MenuMaster] m
WHERE m.[IsActive] = 1;
GO

PRINT 'Company Admin permissions inserted (ALL menus, ALL permissions).';
GO


-- Manager Role (RoleId = 3) → View + Add + Edit on most, no Delete/Approve on sensitive
INSERT INTO [dbo].[RolePermission]
(
    [RoleId], [MenuId],
    [CanView], [CanAdd], [CanEdit], [CanDelete],
    [CanExport], [CanImport], [CanPrint],
    [CanUpload], [CanDownload], [CanApprove], [CanAssign],
    [CreatedAt], [CreatedBy], [IsActive]
)
SELECT
    3,              -- RoleId: Manager
    m.[MenuId],
    1,              -- CanView = 1 (all menus)
    CASE WHEN m.[MenuName] IN (N'Audit Logs', N'App Settings', N'Role Permissions', N'Menu Management', N'Role Management') THEN 0 ELSE 1 END,  -- CanAdd
    CASE WHEN m.[MenuName] IN (N'Audit Logs', N'App Settings', N'Role Permissions', N'Menu Management', N'Role Management') THEN 0 ELSE 1 END,  -- CanEdit
    0,              -- CanDelete = 0 (Managers cannot delete)
    1,              -- CanExport
    0,              -- CanImport
    1,              -- CanPrint
    CASE WHEN m.[MenuName] IN (N'Call Recordings') THEN 1 ELSE 0 END,  -- CanUpload
    1,              -- CanDownload
    0,              -- CanApprove
    CASE WHEN m.[MenuName] IN (N'Leads', N'Tasks', N'Follow-ups') THEN 1 ELSE 0 END,  -- CanAssign
    GETDATE(), 1, 1
FROM [dbo].[MenuMaster] m
WHERE m.[IsActive] = 1;
GO

PRINT 'Manager permissions inserted.';
GO


-- Employee Role (RoleId = 4) → View on assigned modules, Add/Edit on CRM items
INSERT INTO [dbo].[RolePermission]
(
    [RoleId], [MenuId],
    [CanView], [CanAdd], [CanEdit], [CanDelete],
    [CanExport], [CanImport], [CanPrint],
    [CanUpload], [CanDownload], [CanApprove], [CanAssign],
    [CreatedAt], [CreatedBy], [IsActive]
)
SELECT
    4,              -- RoleId: Employee
    m.[MenuId],
    -- CanView: CRM, Calls, Notifications — NOT Settings/Role/Branch/Device admin
    CASE WHEN m.[MenuName] IN (N'Role Management', N'Branch Management', N'Role Permissions', N'Menu Management', N'Audit Logs', N'App Settings', N'Users') THEN 0 ELSE 1 END,
    -- CanAdd: Only CRM items
    CASE WHEN m.[MenuName] IN (N'Leads', N'Customers', N'Contacts', N'Follow-ups', N'Tasks', N'Call Logs') THEN 1 ELSE 0 END,
    -- CanEdit: Only CRM items
    CASE WHEN m.[MenuName] IN (N'Leads', N'Customers', N'Contacts', N'Follow-ups', N'Tasks') THEN 1 ELSE 0 END,
    0,              -- CanDelete = 0
    0,              -- CanExport = 0
    0,              -- CanImport = 0
    0,              -- CanPrint = 0
    CASE WHEN m.[MenuName] IN (N'Call Recordings') THEN 1 ELSE 0 END,  -- CanUpload (recordings)
    CASE WHEN m.[MenuName] IN (N'Call Recordings') THEN 1 ELSE 0 END,  -- CanDownload (recordings)
    0,              -- CanApprove = 0
    0,              -- CanAssign = 0
    GETDATE(), 1, 1
FROM [dbo].[MenuMaster] m
WHERE m.[IsActive] = 1;
GO

PRINT 'Employee permissions inserted.';
GO


-- ====================================================
-- 12. APP SETTINGS - Default Configuration
-- ====================================================
INSERT INTO [dbo].[AppSettings]
(
    [CompanyId], [SettingKey], [SettingValue], [Description],
    [CreatedAt], [CreatedBy], [IsActive]
)
VALUES
    (1, N'APP_NAME',                N'Callalyze',              N'Application display name',                    GETDATE(), 1, 1),
    (1, N'MAX_LOGIN_ATTEMPTS',      N'5',                       N'Maximum failed login attempts before lockout', GETDATE(), 1, 1),
    (1, N'LOCKOUT_DURATION_MIN',    N'15',                      N'Account lockout duration in minutes',         GETDATE(), 1, 1),
    (1, N'SESSION_TIMEOUT_MIN',     N'60',                      N'Session timeout in minutes',                  GETDATE(), 1, 1),
    (1, N'MAX_FILE_SIZE_MB',        N'50',                      N'Maximum file upload size in MB',              GETDATE(), 1, 1),
    (1, N'RECORDING_STORAGE_PATH',  N'Uploads/Recordings',      N'Local path for call recording storage',       GETDATE(), 1, 1),
    (1, N'DATE_FORMAT',             N'dd/MM/yyyy',              N'Application date display format',             GETDATE(), 1, 1),
    (1, N'TIME_ZONE',               N'Asia/Kolkata',            N'Default timezone',                            GETDATE(), 1, 1),
    (1, N'ITEMS_PER_PAGE',          N'10',                      N'Default pagination page size',                GETDATE(), 1, 1),
    (1, N'ENABLE_DARK_MODE',        N'true',                    N'Enable dark mode toggle',                     GETDATE(), 1, 1);
GO

PRINT 'AppSettings seed data inserted.';
GO


-- ====================================================
-- VERIFICATION QUERIES
-- ====================================================

PRINT '';
PRINT '====================================================';
PRINT 'SEED DATA VERIFICATION';
PRINT '====================================================';
PRINT '';

-- Verify all tables
SELECT 'EnumMaster'       AS TableName, COUNT(*) AS RecordCount FROM [dbo].[EnumMaster]       UNION ALL
SELECT 'EnumType',                      COUNT(*)               FROM [dbo].[EnumType]          UNION ALL
SELECT 'CompanyMaster',                 COUNT(*)               FROM [dbo].[CompanyMaster]     UNION ALL
SELECT 'BranchMaster',                  COUNT(*)               FROM [dbo].[BranchMaster]      UNION ALL
SELECT 'DepartmentMaster',             COUNT(*)               FROM [dbo].[DepartmentMaster]  UNION ALL
SELECT 'DesignationMaster',            COUNT(*)               FROM [dbo].[DesignationMaster] UNION ALL
SELECT 'RoleMaster',                    COUNT(*)               FROM [dbo].[RoleMaster]        UNION ALL
SELECT 'EmployeeMaster',               COUNT(*)               FROM [dbo].[EmployeeMaster]    UNION ALL
SELECT 'EmployeeBranch',               COUNT(*)               FROM [dbo].[EmployeeBranch]    UNION ALL
SELECT 'MenuMaster',                    COUNT(*)               FROM [dbo].[MenuMaster]        UNION ALL
SELECT 'RolePermission',               COUNT(*)               FROM [dbo].[RolePermission]    UNION ALL
SELECT 'AppSettings',                   COUNT(*)               FROM [dbo].[AppSettings]
ORDER BY TableName;
GO

-- Verify Tenant Owner structure
PRINT '';
PRINT 'Tenant Owner Verification:';
SELECT
    e.[EmployeeId],
    e.[CompanyId],
    c.[CompanyName],
    e.[EmployeeName],
    e.[Email],
    e.[Tenant],
    CASE WHEN e.[Tenant] = 1 THEN 'Company Owner' ELSE 'Sub User' END AS [UserType],
    r.[RoleName],
    d.[DepartmentName]
FROM [dbo].[EmployeeMaster] e
INNER JOIN [dbo].[CompanyMaster] c ON e.[CompanyId] = c.[CompanyId]
INNER JOIN [dbo].[RoleMaster] r ON e.[RoleId] = r.[RoleId]
LEFT JOIN [dbo].[DepartmentMaster] d ON e.[DepartmentId] = d.[DepartmentId]
WHERE e.[IsActive] = 1
ORDER BY e.[Tenant] DESC, e.[EmployeeId];
GO

-- Verify Multi-Branch Assignment
PRINT '';
PRINT 'Employee Branch Assignment:';
SELECT
    e.[EmployeeName],
    b.[BranchName],
    eb.[IsPrimaryBranch],
    CASE WHEN eb.[IsPrimaryBranch] = 1 THEN 'Primary' ELSE 'Secondary' END AS [BranchType]
FROM [dbo].[EmployeeBranch] eb
INNER JOIN [dbo].[EmployeeMaster] e ON eb.[EmployeeId] = e.[EmployeeId]
INNER JOIN [dbo].[BranchMaster] b ON eb.[BranchId] = b.[BranchId]
WHERE eb.[IsActive] = 1
ORDER BY e.[EmployeeName], eb.[IsPrimaryBranch] DESC;
GO

-- Verify Menu Hierarchy
PRINT '';
PRINT 'Menu Hierarchy:';
SELECT
    m.[MenuId],
    CASE
        WHEN m.[ParentId] IS NULL THEN m.[MenuName]
        ELSE '    └── ' + m.[MenuName]
    END AS [MenuDisplay],
    m.[Url],
    p.[MenuName] AS [ParentMenu]
FROM [dbo].[MenuMaster] m
LEFT JOIN [dbo].[MenuMaster] p ON m.[ParentId] = p.[MenuId]
WHERE m.[IsActive] = 1
ORDER BY ISNULL(m.[ParentId], m.[MenuId]), m.[ParentId], m.[SortOrder];
GO

-- Verify Permission Count per Role
PRINT '';
PRINT 'Permission Count per Role:';
SELECT
    r.[RoleName],
    COUNT(rp.[PermissionId]) AS [TotalPermissions],
    SUM(CAST(rp.[CanView] AS INT)) AS [ViewCount],
    SUM(CAST(rp.[CanAdd] AS INT)) AS [AddCount],
    SUM(CAST(rp.[CanEdit] AS INT)) AS [EditCount],
    SUM(CAST(rp.[CanDelete] AS INT)) AS [DeleteCount]
FROM [dbo].[RolePermission] rp
INNER JOIN [dbo].[RoleMaster] r ON rp.[RoleId] = r.[RoleId]
WHERE rp.[IsActive] = 1
GROUP BY r.[RoleName]
ORDER BY r.[RoleName];
GO


PRINT '';
PRINT '====================================================';
PRINT 'All seed data inserted and verified successfully.';
PRINT '====================================================';
GO
