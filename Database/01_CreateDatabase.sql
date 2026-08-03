-- ====================================================
-- CALLMATRIX ERP + CRM DATABASE CREATION SCRIPT
-- Multi-Tenant SaaS Application
-- SQL Server 2019+
-- Generated: Production-Ready
-- ====================================================

USE [master];
GO

-- Drop database if exists (ONLY for development - remove in production)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CallMatrixDB')
BEGIN
    ALTER DATABASE [CallMatrixDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CallMatrixDB];
END
GO

-- Create Database
CREATE DATABASE [CallMatrixDB]
ON PRIMARY
(
    NAME = N'CallMatrixDB',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CallMatrixDB.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME = N'CallMatrixDB_log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CallMatrixDB_log.ldf',
    SIZE = 50MB,
    MAXSIZE = 2048MB,
    FILEGROWTH = 32MB
);
GO

-- Set Recovery Model
ALTER DATABASE [CallMatrixDB] SET RECOVERY FULL;
GO

-- Enable Read Committed Snapshot Isolation
ALTER DATABASE [CallMatrixDB] SET READ_COMMITTED_SNAPSHOT ON;
GO

-- Set Compatibility Level
ALTER DATABASE [CallMatrixDB] SET COMPATIBILITY_LEVEL = 150;
GO

PRINT '====================================================';
PRINT 'Database [CallMatrixDB] created successfully.';
PRINT '====================================================';
GO
