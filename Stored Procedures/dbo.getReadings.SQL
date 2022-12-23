USE AquaStats
GO

DROP PROCEDURE IF EXISTS dbo.getReadings
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: gets overview of water parameters
--
-- 12/22/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ] 

CREATE PROCEDURE dbo.getReadings
	@json varchar(4000)
AS BEGIN TRY
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Boilerplate
	-------------------------------------------------------------------------------------------------------------------------------
	SET NOCOUNT ON
	SET XACT_ABORT ON
		
	DECLARE @SpState int = 0
	DECLARE @TS datetime2 = sysdatetime()
	
	-- Clean up the JSON payload (remove white spaces) -> ASCII code 9 is a tab, 13 is new line
	SET @json = LTRIM(RTRIM(REPLACE(REPLACE(@json, char(13), ''), char(9), '')))

	DECLARE @Log SpLog 
	INSERT INTO @Log
	SELECT concat(OBJECT_SCHEMA_NAME(@@PROCID), '.', OBJECT_NAME(@@PROCID)), 0, 0, @json, 'Sucessful', '{}', @@SPID, @SpState, @TS

	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Vars & param validation
	-------------------------------------------------------------------------------------------------------------------------------
	IF ISJSON(@json) != 1 BEGIN
		;THROW 50100, 'Param is invalid JSON object', @SpState
		END

	DECLARE @AquariumID int = json_value(@json, '$.AquariumID')
	IF NOT EXISTS (SELECT 1 FROM dbo.Aquariums WHERE AquariumID = @AquariumID) BEGIN
-- this is ONLY for development. This should throw an error
-- ;THROW 50600, 'Passed AquariumID is invalid, not found in DB', @SpState
		SET @AquariumID = 1
		END

    DECLARE @R table (
		AquariumID int,
		TS datetime,
		Temperature decimal(5,2),
		PH decimal(3,1)
		)
    

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------

	-- round timestamps to the nearest minute & combine
	;WITH cTime AS (
		SELECT
			AQ.AquariumID,
			RT.Temperature,
			COALESCE(
				format(RT.[TimeStamp], 'yyyy-MM-dd hh:mm'),
				format(RP.[TimeStamp], 'yyyy-MM-dd hh:mm')) AS TS,
			RP.PH
		FROM dbo.Aquariums AQ
			LEFT JOIN Readings.Temperature RT ON AQ.AquariumID = RT.AquariumID
			LEFT JOIN Readings.PH RP ON AQ.AquariumID = RP.AquariumID
		WHERE 
			AQ.AquariumID = @AquariumID
		)
	-- then, average the readings for each min
	INSERT INTO @R
	SELECT
		AquariumID,
		TS,
		avg(Temperature),
		min(PH)
	FROM cTime
	GROUP BY AquariumID, TS

-- !!! PH grouping is wrong !!!

	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log
	SELECT * FROM @R

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
EXEC dbo.getReadings '{}'