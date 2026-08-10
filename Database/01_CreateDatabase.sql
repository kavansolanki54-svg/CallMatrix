-- ====================================================
-- CALLALYZE ERP + CRM DATABASE CREATION SCRIPT
-- Multi-Tenant SaaS Application
-- SQL Server 2019+
-- Generated: Production-Ready
-- ====================================================

USE [master];
GO

-- Drop database if exists (ONLY for development - remove in production)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CallalyzeDB')
BEGIN
    ALTER DATABASE [CallalyzeDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CallalyzeDB];
END
GO

-- Create Database
CREATE DATABASE [CallalyzeDB]
ON PRIMARY
(
    NAME = N'CallalyzeDB',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CallalyzeDB.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME = N'CallalyzeDB_log',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CallalyzeDB_log.ldf',
    SIZE = 50MB,
    MAXSIZE = 2048MB,
    FILEGROWTH = 32MB
);
GO

-- Set Recovery Model
ALTER DATABASE [CallalyzeDB] SET RECOVERY FULL;
GO

-- Enable Read Committed Snapshot Isolation
ALTER DATABASE [CallalyzeDB] SET READ_COMMITTED_SNAPSHOT ON;
GO

-- Set Compatibility Level
ALTER DATABASE [CallalyzeDB] SET COMPATIBILITY_LEVEL = 150;
GO

PRINT '====================================================';
PRINT 'Database [CallalyzeDB] created successfully.';
PRINT '====================================================';
GO
