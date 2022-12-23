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
	IF ISJSON(@json) != 1 BEGIN
		;THROW 50100, 'Param is invalid JSON object', @SpState
		END


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
		
	DECLARE @Readings table (
		AquariumID int, 
		PH decimal(5,2),
		Temperature decimal(5,2),
		Ammonia decimal(5,2),
		Nitrite decimal(5,2),
		Nitrate decimal(5,2),
		Alkalinity decimal(7,1),		-- in PPM
		GeneralHardness  decimal(7,1),	-- in PPM
		Phosphate decimal(5,2)
		)

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @Readings
	SELECT
		AquariumID		= JSON_VALUE(@json, '$.AquariumID'),
		PH				= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.PH'))),
		Temperature		= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Temperature'))),
		Ammonia			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Ammonia'))),
		Nitrite			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Nitrite'))),
		Nitrate			= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Nitrate'))),
		Alkalinity		= LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.Alkalinity'))),
		GeneralHardness = LTRIM(RTRIM(JSON_VALUE(@json, '$.Readings.GeneralHardness'))),
		Phosphate		= NULL -- I'm not really ready to handle saltwater, yet

	INSERT INTO Readings.Ph (AquariumID, PH, [TimeStamp])
	SELECT 
		AquariumID,
		PH,
		-- is this the way I want to handle timestamps? Or, do I want somethign wiht timezones?
		getdate()
	FROM @Readings 
	WHERE PH IS NOT NULL

	INSERT INTO Readings.Temperature (AquariumID, Temperature, [TimeStamp])
	SELECT
		AquariumID,
		Temperature,
		getdate()
	FROM @Readings
	WHERE Temperature IS NOT NULL		
	
	INSERT INTO Readings.Ammonia (AquariumID, Ammonia, [TimeStamp])
	SELECT
		AquariumID,
		Ammonia,
		getdate()
	FROM @Readings
	WHERE Ammonia IS NOT NULL

	INSERT INTO Readings.Nitrite (AquariumID, Nitrite, [TimeStamp])
	SELECT
		AquariumID,
		Nitrite,
		getdate()
	FROM @Readings
	WHERE Nitrite IS NOT NULL

	INSERT INTO Readings.Nitrate (AquariumID, Nitrate, [TimeStamp])
	SELECT
		AquariumID,
		Nitrate,
		getdate()
	FROM @Readings
	WHERE Nitrate IS NOT NULL

	INSERT INTO Readings.Alkalinity (AquariumID, Alkalinity, [TimeStamp])
	SELECT
		AquariumID,
		Alkalinity,
		getdate()
	FROM @Readings
	WHERE Alkalinity IS NOT NULL

	INSERT INTO Readings.GeneralHardness (AquariumID, GeneralHardness, [TimeStamp])
	SELECT
		AquariumID,
		GeneralHardness,
		getdate()
	FROM @Readings
	WHERE GeneralHardness IS NOT NULL

	INSERT INTO Readings.Phosphate (AquariumID, Phosphate, [TimeStamp])
	SELECT
		AquariumID,
		Phosphate,
		getdate()
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
		"PH":7.1,
		"Temperature":79,
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
