USE AquaStats
GO

-- Dropping and re-creating is an intentional move on my part. I have found some odd behvaior in the past with execution
--	plans when ALTERing procedures
DROP PROCEDURE IF EXISTS dbo.saveReadings
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: Saves water parameters
--
-- 12/13/22		Alex	init
-- 12/24/22		Alex	Modified to account for change to schema & addition on reading events
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ]

CREATE PROCEDURE dbo.saveReadings
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
	-- I expect a JSON payload that looks like this:
	/*
	'{
		"AquariumID":1,
		"Readings":{
			"PH":7.2,
			"Temperature":78.5,
			"Ammonia":0.0,
			"Nitrite":0.25,
			"Nitrate":10,
			"Alkalinity":400,
			"GeneralHardness":400
			}
	}'
	*/


	-- Validate some params
	IF ISJSON(@json) != 1 BEGIN
		;THROW 50100, 'Param is invalid JSON object', @SpState
		END

	DECLARE @AquariumID int = json_value(@json, '$.AquariumID')
	IF NOT EXISTS (SELECT 1 FROM dbo.Aquariums WHERE AquariumID = @AquariumID) BEGIN
		;THROW 50200, 'AquariumID is invalid, not found in DB.', @SpState
		END

	DECLARE @UserID int = (SELECT UserID FROM dbo.Aquariums WHERE AquariumID = @AquariumID)
	IF @UserID IS NULL BEGIN
		;THROW 50300, 'There is no user associtated to this aquarium. You should never see this error!', @SpState
		END

	DECLARE @TZ varchar(128)
	SELECT
		@TZ = coalesce(Timezone, 'UTC')
	FROM dbo.Users
	WHERE UserID = @UserID
		

	-- this will hold the readings
	DECLARE @Readings table (
		AquariumID int, 
		PH decimal(5,2),
		Temperature decimal(5,2),
		Ammonia decimal(5,2),
		Nitrite decimal(5,2),
		Nitrate decimal(5,2),
		Alkalinity decimal(7,1),	
		GeneralHardness  decimal(7,1),
		Phosphate decimal(5,2)
		)
	-- get water parameter info out of JSON param
	INSERT INTO @Readings
	SELECT
		AquariumID		= @AquariumID,
		PH				= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.PH'))),
		Temperature		= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Temperature'))),
		Ammonia			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Ammonia'))),
		Nitrite			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Nitrite'))),
		Nitrate			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Nitrate'))),
		Alkalinity		= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Alkalinity'))),
		GeneralHardness = LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.GeneralHardness'))),
		Phosphate		= NULL -- I'm not really ready to handle saltwater, yet


	-- To hold created eventID temporarily 
	DECLARE @Events table (EventID bigint)

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	-- Create the reading event
	INSERT INTO Readings.[Events] (AquariumID, [TimeStamp])
	OUTPUT inserted.EventID INTO @Events
	SELECT
		@AquariumID,
		getdate() AT TIME ZONE @TZ

	IF (SELECT count(EventID) FROM @Events) != 1 BEGIN
		;THROW 60100, 'More then one event created. You should never see this error.', @SpState
		END
	DECLARE @EventID int
	SET @EventID = (SELECT EventID FROM @Events)


	-- Create entries in the Readings tables, associated to the event that was just created
	INSERT INTO Readings.Ph (PH, EventID)
	SELECT 
		PH,
		@EventID
	FROM @Readings 
	WHERE PH IS NOT NULL

	INSERT INTO Readings.Temperature (Temperature, EventID)
	SELECT
		Temperature,
		@EventID
	FROM @Readings
	WHERE Temperature IS NOT NULL		
	
	INSERT INTO Readings.Ammonia (Ammonia, EventID)
	SELECT
		Ammonia,
		@EventID
	FROM @Readings
	WHERE Ammonia IS NOT NULL

	INSERT INTO Readings.Nitrite (Nitrite, EventID)
	SELECT
		Nitrite,
		@EventID
	FROM @Readings
	WHERE Nitrite IS NOT NULL

	INSERT INTO Readings.Nitrate (Nitrate, EventID)
	SELECT
		Nitrate,
		@EventID
	FROM @Readings
	WHERE Nitrate IS NOT NULL

	INSERT INTO Readings.Alkalinity (Alkalinity, EventID)
	SELECT
		Alkalinity,
		@EventID
	FROM @Readings
	WHERE Alkalinity IS NOT NULL

	INSERT INTO Readings.GeneralHardness (GeneralHardness, EventID)
	SELECT
		GeneralHardness,
		@EventID
	FROM @Readings
	WHERE GeneralHardness IS NOT NULL

	INSERT INTO Readings.Phosphate (Phosphate, EventID)
	SELECT
		Phosphate,
		@EventID
	FROM @Readings
	WHERE Phosphate IS NOT NULL



	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log
	-- SELECT * FROM @Return

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

-- Test?
EXEC dbo.saveReadings '{
	"AquariumID":1,
	"Readings":{
		"PH":7.0,
		"Temperature":77.3,
		"Ammonia":0.0,
		"Nitrite":0.25,
		"Nitrate":10,
		"Alkalinity":400,
		"GeneralHardness":400
		}
	}'
GO

SELECT TOP 1 * FROM Logging.SpLog ORDER BY RecordID DESC

SELECT * FROM Readings.PH
SELECT * FROM Readings.Temperature
SELECT * FROM Readings.Ammonia
