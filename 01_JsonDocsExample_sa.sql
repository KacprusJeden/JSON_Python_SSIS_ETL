CREATE DATABASE JsonDocsExample;
GO

USE JsonDocsExample;
GO


CREATE ROLE programmer;

GRANT CREATE TABLE TO programmer;
GRANT CREATE VIEW TO programmer;
GRANT CREATE PROCEDURE TO programmer;
GRANT DROP PROCEDURE TO programmer;
GRANT CREATE FUNCTION TO programmer;
GRANT CREATE SCHEMA TO programmer;
GRANT CREATE TYPE TO programmer;
GRANT CREATE ASSEMBLY TO programmer;
GRANT CREATE SYNONYM TO programmer;
GRANT SHOWPLAN TO programmer;

GRANT SELECT, INSERT, UPDATE, DELETE, ALTER, REFERENCES ON DATABASE::[JsonDocsExample] TO programmer;

GRANT EXECUTE TO programmer;


CREATE ROLE analytic;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON DATABASE::[JsonDocsExample] TO analytic;



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
    DECLARE @SchemaName SYSNAME, @TableName SYSNAME;
    SELECT 
        @SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'SYSNAME'),
        @TableName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME');
 

	DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'ALTER AUTHORIZATION ON OBJECT::[' + @SchemaName + '].[' + @TableName + '] TO [' + @SchemaName + '];';
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

CREATE LOGIN prog WITH PASSWORD = 'prog123';
CREATE USER prog FOR LOGIN prog;
CREATE SCHEMA prog AUTHORIZATION prog;

ALTER USER prog WITH DEFAULT_SCHEMA = prog;
ALTER ROLE programmer ADD MEMBER prog;


-- user and schema pythondev
CREATE LOGIN pythondev WITH PASSWORD = 'pythondev';
CREATE USER pythondev FOR LOGIN pythondev;
CREATE SCHEMA pythondev AUTHORIZATION pythondev;

ALTER USER pythondev WITH DEFAULT_SCHEMA = pythondev;
ALTER ROLE programmer ADD MEMBER pythondev;

-- user and schema ssis
drop login ssis;
CREATE LOGIN ssis WITH PASSWORD = 'ssis';
CREATE USER ssis FOR LOGIN ssis;
CREATE SCHEMA ssis AUTHORIZATION ssis;

ALTER USER ssis WITH DEFAULT_SCHEMA = ssis;
ALTER ROLE programmer ADD MEMBER ssis;

-- schema docsexample
CREATE SCHEMA [docsexample] AUTHORIZATION [dbo];