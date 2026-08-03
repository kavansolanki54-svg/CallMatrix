-- ====================================================
-- CREATE TABLE [dbo].[DesignationMaster]
-- ====================================================
USE [CallMatrixDB];
GO

IF OBJECT_ID('dbo.DesignationMaster', 'U') IS NOT NULL
    DROP TABLE dbo.DesignationMaster;
GO

CREATE TABLE [dbo].[DesignationMaster]
(
    [DesignationId]     INT IDENTITY(1,1)   NOT NULL,
    [CompanyId]         INT                 NOT NULL,
    [DepartmentId]      INT                 NOT NULL,
    [DesignationName]   NVARCHAR(100)       NOT NULL,
    [Description]       NVARCHAR(500)       NULL,

    -- Audit Columns
    [CreatedAt]         DATETIME            NOT NULL    DEFAULT GETDATE(),
    [CreatedBy]         INT                 NULL,
    [UpdatedAt]         DATETIME            NULL,
    [UpdatedBy]         INT                 NULL,
    [IsActive]          BIT                 NOT NULL    DEFAULT 1,
    [Guids]             UNIQUEIDENTIFIER    NOT NULL    DEFAULT NEWID(),

    CONSTRAINT [PK_DesignationMaster] PRIMARY KEY CLUSTERED ([DesignationId] ASC),

    CONSTRAINT [FK_DesignationMaster_CompanyMaster] FOREIGN KEY ([CompanyId])
        REFERENCES [dbo].[CompanyMaster]([CompanyId]),

    CONSTRAINT [FK_DesignationMaster_DepartmentMaster] FOREIGN KEY ([DepartmentId])
        REFERENCES [dbo].[DepartmentMaster]([DepartmentId])
);
GO

PRINT 'Table [DesignationMaster] created.';
GO
