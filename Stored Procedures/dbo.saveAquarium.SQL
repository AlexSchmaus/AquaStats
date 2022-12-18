USE AquaStats
GO

DROP PROCEDURE IF EXISTS dbo.saveAquarium
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: Saves a new aquarium into the DB
--
-- 12/17/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ]

CREATE PROCEDURE dbo.saveAquarium
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

    DECLARE @Ins table (AquariumID int)
    

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	MERGE dbo.Aquariums AQ
	USING (
		SELECT
			*
		FROM openjson(@json)
		WITH (
			UserID		int				'$.UserID',
			[Name]		varchar(256)	'$.Name',
			Volume		float(24)		'$.Vol',
			TypeID		int				'$.TypeID',
			AquariumID	int				'$.AquariumID'
			)) AS src (UserID, Name, Volume, TypeID, AquariumID)
	ON (AQ.AquariumID = src.AquariumID)
	WHEN MATCHED THEN 
		UPDATE 
		SET FriendlyName = src.[Name],
			AquariumVolume = src.Volume,
			AquariumTypeID = TypeID
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (UserID, FriendlyName, AquariumVolume, AquariumTypeID)
		VALUES (src.UserID, src.Name, src.Volume, src.TypeID)
	OUTPUT inserted.AquariumID INTO @Ins;
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log
	SELECT AquariumID FROM @Ins

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



-- Quick Test --
EXEC dbo.saveAquarium '{
"UserID":1, 
"Name":"Big Tank", 
"Vol":50.2, 
"TypeID":3, 
"AquariumID":null
}'

SELECT * FROM dbo.Aquariums