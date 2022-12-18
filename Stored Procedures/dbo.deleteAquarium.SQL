USE AquaStats
GO

DROP PROCEDURE IF EXISTS dbo.deleteAquarium
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: (Soft) deletes an existing aquarium
--
-- 12/17/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ]

CREATE PROCEDURE dbo.deleteAquarium
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
		0, 
		@json, 
		'Sucessful', 
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

	DECLARE @AquariumID int = JSON_VALUE(@json, '$.AquariumID')
	IF NOT EXISTS (SELECT 1 FROM dbo.Aquariums WHERE AquariumID = @AquariumID AND isDeleted = 0) BEGIN
		;THROW 50500, 'Passed AquariumID is invalid, not found in DB', @SpState
		END

    DECLARE @Del table (AquariumID int)
    

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	UPDATE dbo.Aquariums
	SET isDeleted = 1
	OUTPUT inserted.AquariumID INTO @Del
	WHERE AquariumID = @AquariumID
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log
	SELECT AquariumID AS DeletedAquariumID FROM @Del

	INSERT INTO Logging.SpLog (SpName, ErrorCode, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt)
	SELECT SpName, ErrorCode, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt FROM @Log
		
	RETURN 0

END TRY
BEGIN CATCH
	
	UPDATE @Log 
	SET ErrorCode = ERROR_NUMBER(),
		ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime()),
		ReturnMsg = concat('Error on line ', cast(ERROR_LINE() AS varchar(8)), ': ', ERROR_MESSAGE())
		
	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log

	INSERT INTO Logging.SpLog (SpName, ErrorCode, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt)
	SELECT SpName, ErrorCode, ExecTimeInMS, Parameter, ReturnMsg, AdditionalData, ProcessID, SpState, ExecAt FROM @Log
	
	RETURN 1
END CATCH
GO



-------------------------------------------------------------------------------------------------------------------------------
-- Quick Test --
-------------------------------------------------------------------------------------------------------------------------------

-- Shoudl succede	
EXEC dbo.deleteAquarium '{
"AquariumID":3
}'

EXEC dbo.deleteAquarium '{
"AquariumID":4
}'

-- Should Error -> 50500
EXEC dbo.deleteAquarium '{
"AquariumID":999
}'


SELECT * FROM dbo.Aquariums