USE AquaStats
GO

-- Dropping and re-creating is an intentional move on my part. I have found some odd behvaior in the past with execution
--	plans when ALTERing procedures
DROP PROCEDURE IF EXISTS dbo.ProcName -- Old name
DROP PROCEDURE IF EXISTS dbo.Template
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: A template to build SPs off of
--
-- 12/13/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [X] Get started!
-- [ ] Create type for logging
-- [ ] Create logging SP & exec - rather then this

CREATE PROCEDURE dbo.Template
	@json varchar(4000)
AS BEGIN TRY
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Boilerplate
	-------------------------------------------------------------------------------------------------------------------------------
	SET NOCOUNT ON
	SET XACT_ABORT ON
		
	DECLARE @SpState int = 0
	DECLARE @TS datetime2 = sysdatetime()
	
	DECLARE @Log SpLog 
	INSERT INTO @Log
	SELECT
		concat(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), 
		0, 
		@json, 
		'{}', 
		'{}', 
		@@SPID, 
		@SpState, 
		@TS

	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Vars & param validation
	-------------------------------------------------------------------------------------------------------------------------------
	IF ISJSON(@json) != 1 BEGIN
		;THROW 50100, 'Param is invalid JSON object', @SpState
		END
		

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	DECLARE @msg varchar(1024) = JSON_VALUE(@json, '$.msg')
		
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT 
		0 AS ReturnCode,
		ExecTimeInMS,
		@msg AS [Message]
	FROM @Log

	INSERT INTO Logging.SpLog (SpName, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt)
	SELECT SpName, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt FROM @Log
		
	RETURN 0

END TRY
BEGIN CATCH
	SELECT @@ERROR, ERROR_LINE(), ERROR_MESSAGE()
	RETURN 1
END CATCH
GO

-- Test?
EXEC dbo.Template '{"msg":"Hello World"}'
EXEC dbo.Template '{msg Invalid Json payload}'
EXEC dbo.Template '{}'

SELECT * FROM Logging.SpLog