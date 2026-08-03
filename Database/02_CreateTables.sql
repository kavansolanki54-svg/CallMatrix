-- ====================================================
-- CALLMATRIX ERP + CRM - CREATE TABLE SCRIPTS
-- All Tables with PKs, FKs, Defaults, Checks, Constraints
-- ====================================================

USE [CallMatrixDB];
GO


-- ====================================================
-- 1. ENUM MASTER (Lookup Type Categories)
-- ====================================================
CREATE TABLE [dbo].[EnumMaster]
(
    [EnumId]        SMALLINT IDENTITY(1,1)  NOT NULL,
    [TypeName]      NVARCHAR(200)           NOT NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,

    CONSTRAINT [PK_EnumMaster] PRIMARY KEY CLUSTERED ([EnumId] ASC)
);
GO

PRINT 'Table [EnumMaster] created.';
GO


-- ====================================================
-- 2. ENUM TYPE (Lookup Values)
-- ====================================================
CREATE TABLE [dbo].[EnumType]
(
    [EnumTypeId]    INT IDENTITY(1,1)       NOT NULL,
    [EnumId]        SMALLINT                NOT NULL,
    [EnumTypeName]  NVARCHAR(200)           NOT NULL,
    [SortOrder]     INT                     NOT NULL    DEFAULT 0,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,

    CONSTRAINT [PK_EnumType] PRIMARY KEY CLUSTERED ([EnumTypeId] ASC),

    CONSTRAINT [FK_EnumType_EnumMaster] FOREIGN KEY ([EnumId])
        REFERENCES [dbo].[EnumMaster]([EnumId])
);
GO

PRINT 'Table [EnumType] created.';
GO


-- ====================================================
-- 3. COMPANY MASTER (Tenant Root)
-- ====================================================
CREATE TABLE [dbo].[CompanyMaster]
(
    [CompanyId]     INT IDENTITY(1,1)       NOT NULL,
    [CompanyName]   NVARCHAR(200)           NOT NULL,
    [CompanyCode]   NVARCHAR(50)            NOT NULL,
    [Industry]      NVARCHAR(100)           NULL,
    [Website]       NVARCHAR(200)           NULL,
    [Email]         NVARCHAR(200)           NULL,
    [Phone]         NVARCHAR(20)            NULL,
    [Address]       NVARCHAR(500)           NULL,
    [Country]       NVARCHAR(100)           NULL,
    [State]         NVARCHAR(100)           NULL,
    [City]          NVARCHAR(100)           NULL,
    [Pincode]       NVARCHAR(20)            NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_CompanyMaster] PRIMARY KEY CLUSTERED ([CompanyId] ASC),

    CONSTRAINT [UQ_CompanyMaster_CompanyCode] UNIQUE NONCLUSTERED ([CompanyCode])
);
GO

PRINT 'Table [CompanyMaster] created.';
GO


-- ====================================================
-- 4. BRANCH MASTER
-- ====================================================
CREATE TABLE [dbo].[BranchMaster]
(
    [BranchId]      INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [BranchName]    NVARCHAR(200)           NOT NULL,
    [BranchCode]    NVARCHAR(50)            NULL,
    [Address]       NVARCHAR(500)           NULL,
    [Country]       NVARCHAR(100)           NULL,
    [State]         NVARCHAR(100)           NULL,
    [City]          NVARCHAR(100)           NULL,
    [Pincode]       NVARCHAR(20)            NULL,
    [Phone]         NVARCHAR(20)            NULL,
    [Email]         NVARCHAR(200)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_BranchMaster] PRIMARY KEY CLUSTERED ([BranchId] ASC),

    CONSTRAINT [FK_BranchMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId])
);
GO

PRINT 'Table [BranchMaster] created.';
GO


-- ====================================================
-- 5. DEPARTMENT MASTER
-- ====================================================
CREATE TABLE [dbo].[DepartmentMaster]
(
    [DepartmentId]      INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [DepartmentName]    NVARCHAR(100)       NOT NULL,
    [DepartmentCode]    NVARCHAR(50)        NULL,
    [Description]       NVARCHAR(500)       NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_DepartmentMaster] PRIMARY KEY CLUSTERED ([DepartmentId] ASC),

    CONSTRAINT [FK_DepartmentMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId])
);
GO

PRINT 'Table [DepartmentMaster] created.';
GO


-- ====================================================
-- 6. DESIGNATION MASTER
-- ====================================================
CREATE TABLE [dbo].[DesignationMaster]
(
    [DesignationId]     INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [DepartmentId]      INT                 NOT NULL,
    [DesignationName]   NVARCHAR(100)       NOT NULL,
    [Description]       NVARCHAR(500)       NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_DesignationMaster] PRIMARY KEY CLUSTERED ([DesignationId] ASC),

    CONSTRAINT [FK_DesignationMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_DesignationMaster_DepartmentMaster] FOREIGN KEY ([DepartmentId])
        REFERENCES [dbo].[DepartmentMaster]([DepartmentId])
);
GO

PRINT 'Table [DesignationMaster] created.';
GO


-- ====================================================
-- 7. ROLE MASTER
-- ====================================================
CREATE TABLE [dbo].[RoleMaster]
(
    [RoleId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [RoleName]      NVARCHAR(100)           NOT NULL,
    [RoleTypeId]    INT                     NOT NULL,
    [Description]   NVARCHAR(500)           NULL,
    [IsSystem]      BIT                     NOT NULL    DEFAULT 0,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_RoleMaster] PRIMARY KEY CLUSTERED ([RoleId] ASC),

    CONSTRAINT [FK_RoleMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_RoleMaster_EnumType] FOREIGN KEY ([RoleTypeId])
        REFERENCES [dbo].[EnumType]([EnumTypeId])
);
GO

PRINT 'Table [RoleMaster] created.';
GO


-- ====================================================
-- 8. EMPLOYEE MASTER (Tenant Owner + Sub Users)
-- ====================================================
CREATE TABLE [dbo].[EmployeeMaster]
(
    [EmployeeId]        INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [DepartmentId]      INT                 NULL,
    [DesignationId]     INT                 NULL,
    [RoleId]            INT                 NOT NULL,
    [EmployeeCode]      NVARCHAR(50)        NOT NULL,
    [FirstName]         NVARCHAR(100)       NOT NULL,
    [MiddleName]        NVARCHAR(100)       NULL,
    [LastName]          NVARCHAR(100)       NULL,

    -- Computed Column: Full Name
    [EmployeeName]      AS (
                            CONCAT_WS(' ',
                                NULLIF(LTRIM(RTRIM([FirstName])), ''),
                                NULLIF(LTRIM(RTRIM([MiddleName])), ''),
                                NULLIF(LTRIM(RTRIM([LastName])), '')
                            )
                        ) PERSISTED,

    [Email]             NVARCHAR(200)       NOT NULL,
    [Phone]             NVARCHAR(20)        NULL,
    [Password]          NVARCHAR(MAX)       NULL,
    [ProfileImageUrl]   NVARCHAR(500)       NULL,
    [LastLoginAt]       DATETIME            NULL,

    -- Tenant Flag: 1 = Company Owner, 0 = Sub User / Employee
    [Tenant]            BIT                 NOT NULL    DEFAULT 0,

    -- Audit Columns (NO FK on CreatedBy/UpdatedBy - self-referencing exception)
    [CreatedAt]         DATETIME            NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]         INT                 NULL,
    [UpdatedAt]         DATETIME            NULL,
    [UpdatedBy]         INT                 NULL,
    [IsActive]          BIT                 NOT NULL    DEFAULT 1,
    [Guids]             UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_EmployeeMaster] PRIMARY KEY CLUSTERED ([EmployeeId] ASC),

    CONSTRAINT [FK_EmployeeMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_EmployeeMaster_DepartmentMaster] FOREIGN KEY ([DepartmentId])
        REFERENCES [dbo].[DepartmentMaster]([DepartmentId]),

    CONSTRAINT [FK_EmployeeMaster_DesignationMaster] FOREIGN KEY ([DesignationId])
        REFERENCES [dbo].[DesignationMaster]([DesignationId]),

    CONSTRAINT [FK_EmployeeMaster_RoleMaster] FOREIGN KEY ([RoleId])
        REFERENCES [dbo].[RoleMaster]([RoleId]),

    CONSTRAINT [UQ_EmployeeMaster_EmployeeCode] UNIQUE NONCLUSTERED ([EmployeeCode]),

    CONSTRAINT [UQ_EmployeeMaster_Email] UNIQUE NONCLUSTERED ([Email])
);
GO

PRINT 'Table [EmployeeMaster] created.';
GO


-- ====================================================
-- 9. EMPLOYEE BRANCH (Multi-Branch Assignment)
-- ====================================================
CREATE TABLE [dbo].[EmployeeBranch]
(
    [EmployeeBranchId]  INT IDENTITY(1,1)   NOT NULL,
    [EmployeeId]        INT                 NOT NULL,
    [BranchId]          INT                 NOT NULL,
    [IsPrimaryBranch]   BIT                 NOT NULL    DEFAULT 0,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_EmployeeBranch] PRIMARY KEY CLUSTERED ([EmployeeBranchId] ASC),

    CONSTRAINT [FK_EmployeeBranch_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [FK_EmployeeBranch_BranchMaster] FOREIGN KEY ([BranchId])
        REFERENCES [dbo].[BranchMaster]([BranchId])
);
GO

PRINT 'Table [EmployeeBranch] created.';
GO


-- ====================================================
-- 10. MENU MASTER (Dynamic Menu System)
-- ====================================================
CREATE TABLE [dbo].[MenuMaster]
(
    [MenuId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NULL,
    [MenuName]      NVARCHAR(100)           NOT NULL,
    [Icon]          NVARCHAR(100)           NULL,
    [Url]           NVARCHAR(300)           NULL,
    [ParentId]      INT                     NULL,
    [SortOrder]     INT                     NOT NULL    DEFAULT 0,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_MenuMaster] PRIMARY KEY CLUSTERED ([MenuId] ASC),

    CONSTRAINT [FK_MenuMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_MenuMaster_ParentMenu] FOREIGN KEY ([ParentId])
        REFERENCES [dbo].[MenuMaster]([MenuId])
);
GO

PRINT 'Table [MenuMaster] created.';
GO


-- ====================================================
-- 11. ROLE PERMISSION (RBAC Permission Matrix)
-- ====================================================
CREATE TABLE [dbo].[RolePermission]
(
    [PermissionId]  INT IDENTITY(1,1)       NOT NULL,
    [RoleId]        INT                     NOT NULL,
    [MenuId]        INT                     NOT NULL,

    -- Permission Flags
    [CanView]       BIT                     NOT NULL    DEFAULT 0,
    [CanAdd]        BIT                     NOT NULL    DEFAULT 0,
    [CanEdit]       BIT                     NOT NULL    DEFAULT 0,
    [CanDelete]     BIT                     NOT NULL    DEFAULT 0,
    [CanExport]     BIT                     NOT NULL    DEFAULT 0,
    [CanImport]     BIT                     NOT NULL    DEFAULT 0,
    [CanPrint]      BIT                     NOT NULL    DEFAULT 0,
    [CanUpload]     BIT                     NOT NULL    DEFAULT 0,
    [CanDownload]   BIT                     NOT NULL    DEFAULT 0,
    [CanApprove]    BIT                     NOT NULL    DEFAULT 0,
    [CanAssign]     BIT                     NOT NULL    DEFAULT 0,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_RolePermission] PRIMARY KEY CLUSTERED ([PermissionId] ASC),

    CONSTRAINT [FK_RolePermission_RoleMaster] FOREIGN KEY ([RoleId])
        REFERENCES [dbo].[RoleMaster]([RoleId]),

    CONSTRAINT [FK_RolePermission_MenuMaster] FOREIGN KEY ([MenuId])
        REFERENCES [dbo].[MenuMaster]([MenuId])
);
GO

PRINT 'Table [RolePermission] created.';
GO


-- ====================================================
-- 12. REFRESH TOKEN (JWT Authentication)
-- ====================================================
CREATE TABLE [dbo].[RefreshToken]
(
    [RefreshTokenId]    INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [EmployeeId]        INT                 NOT NULL,
    [Token]             NVARCHAR(MAX)       NOT NULL,
    [ExpiresAt]         DATETIME            NOT NULL,
    [RevokedAt]         DATETIME            NULL,
    [IsRevoked]         BIT                 NOT NULL    DEFAULT 0,
    [CreatedByIp]       NVARCHAR(100)       NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_RefreshToken] PRIMARY KEY CLUSTERED ([RefreshTokenId] ASC),

    CONSTRAINT [FK_RefreshToken_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_RefreshToken_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId])
);
GO

PRINT 'Table [RefreshToken] created.';
GO


-- ====================================================
-- 13. LOGIN HISTORY
-- ====================================================
CREATE TABLE [dbo].[LoginHistory]
(
    [LoginHistoryId]    INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [EmployeeId]        INT                 NOT NULL,
    [LoginAt]           DATETIME            NOT NULL    DEFAULT GETDATE(),
    [LogoutAt]          DATETIME            NULL,
    [IPAddress]         NVARCHAR(100)       NULL,
    [UserAgent]         NVARCHAR(500)       NULL,
    [DeviceInfo]        NVARCHAR(500)       NULL,
    [Status]            NVARCHAR(50)        NOT NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_LoginHistory] PRIMARY KEY CLUSTERED ([LoginHistoryId] ASC),

    CONSTRAINT [FK_LoginHistory_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_LoginHistory_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_LoginHistory_Status] CHECK ([Status] IN ('Success', 'Failed', 'Locked'))
);
GO

PRINT 'Table [LoginHistory] created.';
GO


-- ====================================================
-- 14. LEAD MASTER (CRM)
-- ====================================================
CREATE TABLE [dbo].[LeadMaster]
(
    [LeadId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [FirstName]     NVARCHAR(100)           NOT NULL,
    [LastName]      NVARCHAR(100)           NULL,
    [Email]         NVARCHAR(200)           NULL,
    [Phone]         NVARCHAR(20)            NULL,
    [Status]        NVARCHAR(50)            NOT NULL    DEFAULT 'New',
    [Source]        NVARCHAR(100)           NULL,
    [AssignedTo]    INT                     NULL,
    [Description]   NVARCHAR(MAX)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_LeadMaster] PRIMARY KEY CLUSTERED ([LeadId] ASC),

    CONSTRAINT [FK_LeadMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_LeadMaster_AssignedTo] FOREIGN KEY ([AssignedTo])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_LeadMaster_Status] CHECK ([Status] IN ('New', 'Assigned', 'InProgress', 'FollowUp', 'Converted', 'Rejected'))
);
GO

PRINT 'Table [LeadMaster] created.';
GO


-- ====================================================
-- 15. CUSTOMER MASTER (CRM)
-- ====================================================
CREATE TABLE [dbo].[CustomerMaster]
(
    [CustomerId]    INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [FirstName]     NVARCHAR(100)           NOT NULL,
    [LastName]      NVARCHAR(100)           NULL,
    [Email]         NVARCHAR(200)           NULL,
    [Phone]         NVARCHAR(20)            NULL,
    [LeadId]        INT                     NULL,
    [Address]       NVARCHAR(500)           NULL,
    [City]          NVARCHAR(100)           NULL,
    [State]         NVARCHAR(100)           NULL,
    [Country]       NVARCHAR(100)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_CustomerMaster] PRIMARY KEY CLUSTERED ([CustomerId] ASC),

    CONSTRAINT [FK_CustomerMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_CustomerMaster_LeadMaster] FOREIGN KEY ([LeadId])
        REFERENCES [dbo].[LeadMaster]([LeadId])
);
GO

PRINT 'Table [CustomerMaster] created.';
GO


-- ====================================================
-- 16. CONTACT MASTER (CRM)
-- ====================================================
CREATE TABLE [dbo].[ContactMaster]
(
    [ContactId]     INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [CustomerId]    INT                     NULL,
    [FirstName]     NVARCHAR(100)           NOT NULL,
    [LastName]      NVARCHAR(100)           NULL,
    [Email]         NVARCHAR(200)           NULL,
    [Phone]         NVARCHAR(20)            NULL,
    [Designation]   NVARCHAR(100)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_ContactMaster] PRIMARY KEY CLUSTERED ([ContactId] ASC),

    CONSTRAINT [FK_ContactMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_ContactMaster_CustomerMaster] FOREIGN KEY ([CustomerId])
        REFERENCES [dbo].[CustomerMaster]([CustomerId])
);
GO

PRINT 'Table [ContactMaster] created.';
GO


-- ====================================================
-- 17. FOLLOW UP (CRM)
-- ====================================================
CREATE TABLE [dbo].[FollowUp]
(
    [FollowUpId]    INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [LeadId]        INT                     NULL,
    [CustomerId]    INT                     NULL,
    [ScheduledDate] DATETIME                NOT NULL,
    [CompletedDate] DATETIME                NULL,
    [Notes]         NVARCHAR(MAX)           NULL,
    [Status]        NVARCHAR(50)            NOT NULL    DEFAULT 'Pending',
    [AssignedTo]    INT                     NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_FollowUp] PRIMARY KEY CLUSTERED ([FollowUpId] ASC),

    CONSTRAINT [FK_FollowUp_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_FollowUp_LeadMaster] FOREIGN KEY ([LeadId])
        REFERENCES [dbo].[LeadMaster]([LeadId]),

    CONSTRAINT [FK_FollowUp_CustomerMaster] FOREIGN KEY ([CustomerId])
        REFERENCES [dbo].[CustomerMaster]([CustomerId]),

    CONSTRAINT [FK_FollowUp_AssignedTo] FOREIGN KEY ([AssignedTo])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_FollowUp_Status] CHECK ([Status] IN ('Pending', 'Completed', 'Missed'))
);
GO

PRINT 'Table [FollowUp] created.';
GO


-- ====================================================
-- 18. NOTE MASTER (CRM)
-- ====================================================
CREATE TABLE [dbo].[NoteMaster]
(
    [NoteId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [LeadId]        INT                     NULL,
    [CustomerId]    INT                     NULL,
    [Content]       NVARCHAR(MAX)           NOT NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_NoteMaster] PRIMARY KEY CLUSTERED ([NoteId] ASC),

    CONSTRAINT [FK_NoteMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_NoteMaster_LeadMaster] FOREIGN KEY ([LeadId])
        REFERENCES [dbo].[LeadMaster]([LeadId]),

    CONSTRAINT [FK_NoteMaster_CustomerMaster] FOREIGN KEY ([CustomerId])
        REFERENCES [dbo].[CustomerMaster]([CustomerId])
);
GO

PRINT 'Table [NoteMaster] created.';
GO


-- ====================================================
-- 19. TASK MASTER (CRM)
-- ====================================================
CREATE TABLE [dbo].[TaskMaster]
(
    [TaskId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [Title]         NVARCHAR(200)           NOT NULL,
    [Description]   NVARCHAR(MAX)           NULL,
    [LeadId]        INT                     NULL,
    [CustomerId]    INT                     NULL,
    [AssignedTo]    INT                     NOT NULL,
    [DueDate]       DATETIME                NULL,
    [CompletedDate] DATETIME                NULL,
    [Status]        NVARCHAR(50)            NOT NULL    DEFAULT 'Pending',
    [Priority]      NVARCHAR(50)            NOT NULL    DEFAULT 'Medium',

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_TaskMaster] PRIMARY KEY CLUSTERED ([TaskId] ASC),

    CONSTRAINT [FK_TaskMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_TaskMaster_LeadMaster] FOREIGN KEY ([LeadId])
        REFERENCES [dbo].[LeadMaster]([LeadId]),

    CONSTRAINT [FK_TaskMaster_CustomerMaster] FOREIGN KEY ([CustomerId])
        REFERENCES [dbo].[CustomerMaster]([CustomerId]),

    CONSTRAINT [FK_TaskMaster_AssignedTo] FOREIGN KEY ([AssignedTo])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_TaskMaster_Status] CHECK ([Status] IN ('Pending', 'InProgress', 'Completed', 'Cancelled')),

    CONSTRAINT [CK_TaskMaster_Priority] CHECK ([Priority] IN ('Low', 'Medium', 'High', 'Urgent'))
);
GO

PRINT 'Table [TaskMaster] created.';
GO


-- ====================================================
-- 20. USER DEVICE (Device Management)
-- ====================================================
CREATE TABLE [dbo].[UserDevice]
(
    [UserDeviceId]  INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [EmployeeId]    INT                     NOT NULL,
    [DeviceId]      NVARCHAR(200)           NOT NULL,
    [IMEI]          NVARCHAR(100)           NULL,
    [Manufacturer]  NVARCHAR(100)           NULL,
    [Model]         NVARCHAR(100)           NULL,
    [OSVersion]     NVARCHAR(100)           NULL,
    [AppVersion]    NVARCHAR(100)           NULL,
    [BatteryLevel]  INT                     NULL,
    [IPAddress]     NVARCHAR(100)           NULL,
    [LastSyncAt]    DATETIME                NULL,
    [Latitude]      DECIMAL(10,7)           NULL,
    [Longitude]     DECIMAL(10,7)           NULL,
    [IsOnline]      BIT                     NOT NULL    DEFAULT 0,
    [IsApproved]    BIT                     NOT NULL    DEFAULT 0,
    [IsBlocked]     BIT                     NOT NULL    DEFAULT 0,
    [Status]        NVARCHAR(50)            NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_UserDevice] PRIMARY KEY CLUSTERED ([UserDeviceId] ASC),

    CONSTRAINT [FK_UserDevice_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_UserDevice_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId])
);
GO

PRINT 'Table [UserDevice] created.';
GO


-- ====================================================
-- 21. CALL MASTER (Call Management)
-- ====================================================
CREATE TABLE [dbo].[CallMaster]
(
    [CallId]        INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [PhoneNumber]   NVARCHAR(20)            NOT NULL,
    [ContactName]   NVARCHAR(200)           NULL,
    [Duration]      INT                     NULL        DEFAULT 0,
    [CallType]      NVARCHAR(50)            NOT NULL,
    [CallDateTime]  DATETIME                NOT NULL,
    [EmployeeId]    INT                     NOT NULL,
    [DeviceId]      INT                     NULL,
    [CustomerId]    INT                     NULL,
    [SyncedAt]      DATETIME                NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_CallMaster] PRIMARY KEY CLUSTERED ([CallId] ASC),

    CONSTRAINT [FK_CallMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_CallMaster_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [FK_CallMaster_UserDevice] FOREIGN KEY ([DeviceId])
        REFERENCES [dbo].[UserDevice]([UserDeviceId]),

    CONSTRAINT [FK_CallMaster_CustomerMaster] FOREIGN KEY ([CustomerId])
        REFERENCES [dbo].[CustomerMaster]([CustomerId]),

    CONSTRAINT [CK_CallMaster_CallType] CHECK ([CallType] IN ('Incoming', 'Outgoing', 'Missed'))
);
GO

PRINT 'Table [CallMaster] created.';
GO


-- ====================================================
-- 22. CALL RECORDING
-- ====================================================
CREATE TABLE [dbo].[CallRecording]
(
    [CallRecordingId]   INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [CallId]            INT                 NOT NULL,
    [FileName]          NVARCHAR(300)       NOT NULL,
    [FilePath]          NVARCHAR(500)       NULL,
    [FileUrl]           NVARCHAR(500)       NULL,
    [Duration]          INT                 NULL        DEFAULT 0,
    [FileSize]          BIGINT              NULL        DEFAULT 0,
    [UploadStatus]      NVARCHAR(50)        NOT NULL    DEFAULT 'Pending',
    [RecordingDate]     DATETIME            NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_CallRecording] PRIMARY KEY CLUSTERED ([CallRecordingId] ASC),

    CONSTRAINT [FK_CallRecording_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_CallRecording_CallMaster] FOREIGN KEY ([CallId])
        REFERENCES [dbo].[CallMaster]([CallId]),

    CONSTRAINT [CK_CallRecording_UploadStatus] CHECK ([UploadStatus] IN ('Pending', 'Uploading', 'Completed', 'Failed'))
);
GO

PRINT 'Table [CallRecording] created.';
GO


-- ====================================================
-- 23. NOTIFICATION
-- ====================================================
CREATE TABLE [dbo].[Notification]
(
    [NotificationId]    INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [EmployeeId]        INT                 NOT NULL,
    [Title]             NVARCHAR(200)       NOT NULL,
    [Message]           NVARCHAR(MAX)       NULL,
    [Type]              NVARCHAR(50)        NOT NULL    DEFAULT 'InApp',
    [IsRead]            BIT                 NOT NULL    DEFAULT 0,
    [ReadAt]            DATETIME            NULL,
    [Data]              NVARCHAR(MAX)       NULL,
    [SentAt]            DATETIME            NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_Notification] PRIMARY KEY CLUSTERED ([NotificationId] ASC),

    CONSTRAINT [FK_Notification_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_Notification_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_Notification_Type] CHECK ([Type] IN ('Push', 'Email', 'InApp'))
);
GO

PRINT 'Table [Notification] created.';
GO


-- ====================================================
-- 24. ACTIVITY LOG
-- ====================================================
CREATE TABLE [dbo].[ActivityLog]
(
    [ActivityLogId] INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [EmployeeId]    INT                     NOT NULL,
    [Action]        NVARCHAR(100)           NOT NULL,
    [EntityType]    NVARCHAR(100)           NOT NULL,
    [EntityId]      INT                     NULL,
    [Description]   NVARCHAR(MAX)           NULL,
    [IPAddress]     NVARCHAR(100)           NULL,
    [UserAgent]     NVARCHAR(500)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_ActivityLog] PRIMARY KEY CLUSTERED ([ActivityLogId] ASC),

    CONSTRAINT [FK_ActivityLog_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_ActivityLog_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId])
);
GO

PRINT 'Table [ActivityLog] created.';
GO


-- ====================================================
-- 25. AUDIT LOG (Database Change Tracking)
-- ====================================================
CREATE TABLE [dbo].[AuditLog]
(
    [AuditLogId]    INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NULL,
    [TableName]     NVARCHAR(200)           NOT NULL,
    [RecordId]      INT                     NULL,
    [Action]        NVARCHAR(50)            NOT NULL,
    [OldValues]     NVARCHAR(MAX)           NULL,
    [NewValues]     NVARCHAR(MAX)           NULL,
    [EmployeeId]    INT                     NULL,
    [Timestamp]     DATETIME                NOT NULL    DEFAULT GETDATE(),

    CONSTRAINT [PK_AuditLog] PRIMARY KEY CLUSTERED ([AuditLogId] ASC),

    CONSTRAINT [FK_AuditLog_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_AuditLog_EmployeeMaster] FOREIGN KEY ([EmployeeId])
        REFERENCES [dbo].[EmployeeMaster]([EmployeeId]),

    CONSTRAINT [CK_AuditLog_Action] CHECK ([Action] IN ('Insert', 'Update', 'Delete'))
);
GO

PRINT 'Table [AuditLog] created.';
GO


-- ====================================================
-- 26. APP SETTINGS (Per-Tenant Configuration)
-- ====================================================
CREATE TABLE [dbo].[AppSettings]
(
    [SettingId]     INT IDENTITY(1,1)       NOT NULL,
    [CompanyId]     INT                     NOT NULL,
    [SettingKey]    NVARCHAR(100)           NOT NULL,
    [SettingValue]  NVARCHAR(MAX)           NULL,
    [Description]   NVARCHAR(500)           NULL,

    -- Audit Columns
    [CreatedAt]     DATETIME                NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]     INT                     NULL,
    [UpdatedAt]     DATETIME                NULL,
    [UpdatedBy]     INT                     NULL,
    [IsActive]      BIT                     NOT NULL    DEFAULT 1,
    [Guids]         UNIQUEIDENTIFIER        NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_AppSettings] PRIMARY KEY CLUSTERED ([SettingId] ASC),

    CONSTRAINT [FK_AppSettings_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [UQ_AppSettings_SettingKey] UNIQUE NONCLUSTERED ([SettingKey])
);
GO

PRINT 'Table [AppSettings] created.';
GO


PRINT '';
PRINT '====================================================';
PRINT 'All 26 tables created successfully.';
PRINT '====================================================';
GO
