CREATE DATABASE JsonDocsExample;
GO

USE JsonDocsExample;
GO


CREATE ROLE programmer
GO

GRANT CREATE TABLE TO programmer
GO
GRANT CREATE VIEW TO programmer
GO
GRANT CREATE PROCEDURE TO programmer
GO
GRANT CREATE FUNCTION TO programmer
GO
GRANT CREATE SCHEMA TO programmer
GO
GRANT CREATE TYPE TO programmer
GO
GRANT CREATE ASSEMBLY TO programmer
GO
GRANT CREATE SYNONYM TO programmer
GO
GRANT SHOWPLAN TO programmer
GO

GRANT SELECT, INSERT, UPDATE, DELETE, ALTER, REFERENCES ON DATABASE::[JsonDocsExample] TO programmer
GO

GRANT EXECUTE TO programmer
GO


CREATE ROLE analytic
GO
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON DATABASE::[JsonDocsExample] TO analytic
GO



CREATE OR ALTER TRIGGER [trg_GrantControlOnSchema]
ON DATABASE
AFTER CREATE_SCHEMA
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SchemaName SYSNAME;
    SELECT @SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME');
    
    DECLARE @SQL NVARCHAR(MAX);

    -- Nadaj pe³n¹ kontrolê roli programmer na nowym schemacie
    SET @SQL = 'GRANT CONTROL ON SCHEMA::[' + @SchemaName + '] TO programmer;';
    EXEC sp_executesql @SQL;

    SET @SQL = 'GRANT ALTER ON SCHEMA::[' + @SchemaName + '] TO programmer;';
    EXEC sp_executesql @SQL;
END;
GO


CREATE OR ALTER TRIGGER [trg_AfterCreateTable]
ON DATABASE
AFTER CREATE_TABLE
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @SchemaName SYSNAME, @TableName SYSNAME, @SchemaOwner SYSNAME;

    SELECT 
        @SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'SYSNAME'),
        @TableName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME');
 
	SELECT @SchemaOwner = dp.Name 
	FROM sys.schemas s
	INNER JOIN sys.database_principals dp on s.principal_id = dp.principal_id
	WHERE s.name = @SchemaName;

	DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'ALTER AUTHORIZATION ON OBJECT::[' + @SchemaName + '].[' + @TableName + '] TO [' + @SchemaOwner + '];';
    EXEC sp_executesql @SQL;

	SET @SQL = 'GRANT SELECT ON [' + @SchemaName + '].[' + @TableName + '] TO programmer;';
    EXEC sp_executesql @SQL;

	SET @SQL = 'GRANT INSERT, UPDATE, DELETE ON [' + @SchemaName + '].[' + @TableName + '] TO programmer;';
    EXEC sp_executesql @SQL;

	SET @SQL = 'GRANT SELECT ON [' + @SchemaName + '].[' + @TableName + '] TO analytic;';
    EXEC sp_executesql @SQL;
END;
GO

-- user and schema prog

CREATE LOGIN prog WITH PASSWORD = 'PrGM!!123##prgm' -- your password
GO
CREATE USER prog FOR LOGIN prog
GO
CREATE SCHEMA prog AUTHORIZATION prog
GO

ALTER USER prog WITH DEFAULT_SCHEMA = prog
GO
ALTER ROLE programmer ADD MEMBER prog
GO


-- user and schema pythondev
CREATE LOGIN pythondev WITH PASSWORD = 'Py!!123##tHon' -- your password
GO
CREATE USER pythondev FOR LOGIN pythondev
GO
CREATE SCHEMA pythondev AUTHORIZATION pythondev
GO

ALTER USER pythondev WITH DEFAULT_SCHEMA = pythondev
GO
ALTER ROLE programmer ADD MEMBER pythondev
GO

-- user and schema ssis
CREATE LOGIN ssis WITH PASSWORD = '!S!!123##sis!' -- your password
GO
CREATE USER ssis FOR LOGIN ssis
GO
CREATE SCHEMA ssis AUTHORIZATION ssis
GO

ALTER USER ssis WITH DEFAULT_SCHEMA = ssis
GO
ALTER ROLE programmer ADD MEMBER ssis
GO

-- schema docsexample
CREATE SCHEMA [docsexample] AUTHORIZATION [dbo]
GO