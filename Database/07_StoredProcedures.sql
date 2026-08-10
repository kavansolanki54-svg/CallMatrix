-- ====================================================
-- CALLALYZE ERP + CRM - STORED PROCEDURES
-- Dynamic queries, Stored Procedures, and TVPs
-- ====================================================

USE [CallalyzeDB];
GO

-- 1. Get Employee By Email
IF OBJECT_ID('dbo.sp_GetEmployeeByEmail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEmployeeByEmail;
GO
CREATE PROCEDURE dbo.sp_GetEmployeeByEmail
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[EmployeeMaster] 
    WHERE [Email] = @Email AND [IsActive] = 1;
END;
GO

-- 2. Get Employee By Code
IF OBJECT_ID('dbo.sp_GetEmployeeByCode', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetEmployeeByCode;
GO
CREATE PROCEDURE dbo.sp_GetEmployeeByCode
    @EmployeeCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[EmployeeMaster] 
    WHERE [EmployeeCode] = @EmployeeCode AND [IsActive] = 1;
END;
GO

-- 3. Get Active Roles By Company
IF OBJECT_ID('dbo.sp_GetActiveRolesByCompany', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetActiveRolesByCompany;
GO
CREATE PROCEDURE dbo.sp_GetActiveRolesByCompany
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[RoleMaster] 
    WHERE [CompanyId] = @CompanyId AND [IsActive] = 1;
END;
GO

-- 4. Get Menus By Role and Company
IF OBJECT_ID('dbo.sp_GetMenusByRoleId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetMenusByRoleId;
GO
CREATE PROCEDURE dbo.sp_GetMenusByRoleId
    @RoleId INT,
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.* 
    FROM [dbo].[MenuMaster] m
    INNER JOIN [dbo].[RolePermission] rp ON m.[MenuId] = rp.[MenuId]
    WHERE rp.[RoleId] = @RoleId 
      AND rp.[CanView] = 1 
      AND rp.[IsActive] = 1
      AND m.[IsActive] = 1
      AND (m.[CompanyId] IS NULL OR m.[CompanyId] = @CompanyId)
    ORDER BY ISNULL(m.[ParentId], m.[MenuId]), m.[SortOrder];
END;
GO

-- 5. Get Permissions By Role
IF OBJECT_ID('dbo.sp_GetPermissionsByRoleId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetPermissionsByRoleId;
GO
CREATE PROCEDURE dbo.sp_GetPermissionsByRoleId
    @RoleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[RolePermission] 
    WHERE [RoleId] = @RoleId AND [IsActive] = 1;
END;
GO

-- 6. Get Permission By Role and Menu
IF OBJECT_ID('dbo.sp_GetPermissionByRoleAndMenu', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetPermissionByRoleAndMenu;
GO
CREATE PROCEDURE dbo.sp_GetPermissionByRoleAndMenu
    @RoleId INT,
    @MenuId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[RolePermission] 
    WHERE [RoleId] = @RoleId AND [MenuId] = @MenuId AND [IsActive] = 1;
END;
GO

-- 7. Get Refresh Token
IF OBJECT_ID('dbo.sp_GetRefreshToken', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetRefreshToken;
GO
CREATE PROCEDURE dbo.sp_GetRefreshToken
    @Token NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[RefreshToken] 
    WHERE [Token] = @Token AND [IsRevoked] = 0 AND [IsActive] = 1;
END;
GO

-- 8. Revoke Tokens By Employee
IF OBJECT_ID('dbo.sp_RevokeTokensByEmployeeId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RevokeTokensByEmployeeId;
GO
CREATE PROCEDURE dbo.sp_RevokeTokensByEmployeeId
    @EmployeeId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE [dbo].[RefreshToken] 
    SET [IsRevoked] = 1, [RevokedAt] = GETDATE() 
    WHERE [EmployeeId] = @EmployeeId AND [IsRevoked] = 0;
END;
GO

-- 9. Get Leads By Company
IF OBJECT_ID('dbo.sp_GetLeadsByCompany', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetLeadsByCompany;
GO
CREATE PROCEDURE dbo.sp_GetLeadsByCompany
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[LeadMaster] 
    WHERE [CompanyId] = @CompanyId AND [IsActive] = 1
    ORDER BY [CreatedAt] DESC;
END;
GO

-- 10. Get Customers By Company
IF OBJECT_ID('dbo.sp_GetCustomersByCompany', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetCustomersByCompany;
GO
CREATE PROCEDURE dbo.sp_GetCustomersByCompany
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[CustomerMaster] 
    WHERE [CompanyId] = @CompanyId AND [IsActive] = 1
    ORDER BY [CreatedAt] DESC;
END;
GO

-- 11. Get Contacts By Customer
IF OBJECT_ID('dbo.sp_GetContactsByCustomer', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetContactsByCustomer;
GO
CREATE PROCEDURE dbo.sp_GetContactsByCustomer
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[ContactMaster] 
    WHERE [CustomerId] = @CustomerId AND [IsActive] = 1;
END;
GO

-- 12. Get Pending FollowUps
IF OBJECT_ID('dbo.sp_GetPendingFollowUps', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetPendingFollowUps;
GO
CREATE PROCEDURE dbo.sp_GetPendingFollowUps
    @AssignedTo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[FollowUp] 
    WHERE [AssignedTo] = @AssignedTo AND [Status] = 'Pending' AND [IsActive] = 1
    ORDER BY [ScheduledDate] ASC;
END;
GO

-- 13. Get Tasks By Assigned Employee
IF OBJECT_ID('dbo.sp_GetTasksByAssignedTo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetTasksByAssignedTo;
GO
CREATE PROCEDURE dbo.sp_GetTasksByAssignedTo
    @AssignedTo INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[TaskMaster] 
    WHERE [AssignedTo] = @AssignedTo AND [IsActive] = 1
    ORDER BY [DueDate] ASC;
END;
GO

-- 14. Get Notes By Lead
IF OBJECT_ID('dbo.sp_GetNotesByLead', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetNotesByLead;
GO
CREATE PROCEDURE dbo.sp_GetNotesByLead
    @LeadId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * 
    FROM [dbo].[NoteMaster] 
    WHERE [LeadId] = @LeadId AND [IsActive] = 1
    ORDER BY [CreatedAt] DESC;
END;
GO

-- 15. Get Lead Timeline
IF OBJECT_ID('dbo.sp_GetLeadTimeline', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetLeadTimeline;
GO
CREATE PROCEDURE dbo.sp_GetLeadTimeline
    @LeadId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        'FollowUp' AS ItemType,
        'Follow-up Scheduled: ' + ISNULL([Notes], '') AS Title,
        [Notes] AS Description,
        [ScheduledDate] AS EventDate,
        e.[EmployeeName] AS PerformedByName
    FROM [dbo].[FollowUp] f
    LEFT JOIN [dbo].[EmployeeMaster] e ON f.[AssignedTo] = e.[EmployeeId]
    WHERE f.[LeadId] = @LeadId AND f.[IsActive] = 1

    UNION ALL

    SELECT 
        'Note' AS ItemType,
        'Note Added' AS Title,
        [Content] AS Description,
        n.[CreatedAt] AS EventDate,
        e.[EmployeeName] AS PerformedByName
    FROM [dbo].[NoteMaster] n
    LEFT JOIN [dbo].[EmployeeMaster] e ON n.[CreatedBy] = e.[EmployeeId]
    WHERE n.[LeadId] = @LeadId AND n.[IsActive] = 1

    UNION ALL

    SELECT 
        'Task' AS ItemType,
        'Task: ' + [Title] AS Title,
        [Description] AS Description,
        t.[CreatedAt] AS EventDate,
        e.[EmployeeName] AS PerformedByName
    FROM [dbo].[TaskMaster] t
    LEFT JOIN [dbo].[EmployeeMaster] e ON t.[AssignedTo] = e.[EmployeeId]
    WHERE t.[LeadId] = @LeadId AND t.[IsActive] = 1

    ORDER BY EventDate DESC;
END;
GO

PRINT 'All Stored Procedures created successfully.';
GO
