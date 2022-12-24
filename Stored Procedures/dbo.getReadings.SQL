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
-- 12/24/22		Alex	Updated to reflect changes in schema (EventID)
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


	DECLARE @StartDate datetime2 = json_value(@json, '$.StartDate')
	IF @StartDate IS NULL BEGIN
		SET @StartDate = (SELECT min([TimeStamp]) FROM Readings.[Events] WHERE AquariumID = @AquariumID)
		END

	DECLARE @StopDate datetime2 = json_value(@json, '$.StopDate')
	IF @StopDate IS NULL BEGIN
		SET @StopDate = (SELECT max([TimeStamp]) FROM Readings.[Events] WHERE AquariumID = @AquariumID)
		END

	DECLARE @TimeSpan int = datediff(second, @StartDate, @StopDate)

    DECLARE @R table (
		AquariumID int,
		TS datetime,
		Temperature decimal(5,2),
		PH decimal(3,1)
		)
    

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------

	-- get every second between the start and stop date, then convert them into an int
	;WITH 
	cTime AS (
		SELECT datediff(second, '2022-01-01', @StartDate) AS TS
		UNION ALL
		SELECT
			datediff(second, '2022-01-01', @StartDate) + N.Number AS TS
		FROM Util.Numbers N
		WHERE N.Number <= @TimeSpan
		),
	-- get all data points between the start and stop date
	cReadings AS (
		SELECT
			Temp.Temperature,
			PH.ph,
			NH3.Ammonia,
			NO2.Nitrite,
			NO3.Nitrate,
			datediff(second, '2022-01-01', [TimeStamp]) AS TS
		FROM Readings.[Events] E
			LEFT JOIN Readings.Temperature Temp ON E.EventID = Temp.EventID
			LEFT JOIN Readings.PH PH ON E.EventID = PH.EventID
			LEFT JOIN Readings.Ammonia NH3 ON E.EventID = NH3.EventID
			LEFT JOIN Readings.Nitrite NO2 ON E.EventID = NO2.EventID
			LEFT JOIN Readings.Nitrate NO3 ON E.EventID = NO3.EventID
		WHERE 
			AquariumID = @AquariumID
			AND [TimeStamp] BETWEEN @StartDate AND @StopDate
		)
	-- join & Spread the data onto time - this way there are no gaps in the data, so we can chart it
	-- GROUP BY & AVG to condense time - one reading per second
	-- turn the timestamp (TS) back into a human readable date time
	SELECT
		format(dateadd(second, TI.TS, '2022-01-01'), 'MM/dd/yy hh:mm:ss') AS DTString,
		AVG(Temperature) AS Temperature,
		AVG(ph) AS ph,
		AVG(Ammonia) AS Ammonia,
		AVG(Nitrite) AS Nitrite,
		AVG(Nitrate) AS Nitrate
	FROM cTime TI
		LEFT JOIN cReadings cR ON TI.TS = cR.TS
	GROUP BY TI.TS
	ORDER BY TI.TS
	


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
EXEC dbo.getReadings '{"AquariumID":1}'

