SET QUOTED_IDENTIFIER ON;
GO

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' NOCHECK CONSTRAINT ALL; '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.type = 'U';

EXEC sp_executesql @sql;

SET @sql = '';
SELECT @sql += 'DELETE FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '; '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.type = 'U' AND t.name NOT IN ('MenuMaster', '__EFMigrationsHistory');

EXEC sp_executesql @sql;

SET @sql = '';
SELECT @sql += 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WITH CHECK CHECK CONSTRAINT ALL; '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.type = 'U';

EXEC sp_executesql @sql;
