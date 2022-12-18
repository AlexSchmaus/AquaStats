USE AquaStats
GO

DROP PROCEDURE IF EXISTS dbo.createUser
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: Saves a new user into the DB
--
-- 12/17/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ]

CREATE PROCEDURE dbo.createUser
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

    DECLARE @Ins table (UserID int)
    DECLARE @Password varbinary(4000) = CAST('123' AS binary(3)) -- PLACEHOLDER
    

	-------------------------------------------------------------------------------------------------------------------------------
	-- Logic
	-------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO dbo.Users (
        UserName,	
        EmailAddress,
        FirstName,	
        LastName,	
        [Password],	
        Salt
		)
    OUTPUT inserted.UserID INTO @Ins		
    SELECT 
        json_value(@json, '$.UserName'),
        json_value(@json, '$.EmailAddress'),
        json_value(@json, '$.FirstName'),
        json_value(@json, '$.LastName'),
        @Password,		
        CRYPT_GEN_RANDOM(128) --convert(varchar(256), CRYPT_GEN_RANDOM(32), 2) 

    IF (SELECT count(UserID) FROM @Ins) != 1 BEGIN 
        ;THROW 70100, 'Error saving user account', @SpState
        END
	
	-------------------------------------------------------------------------------------------------------------------------------
	-- Standard Return & Logging
	-------------------------------------------------------------------------------------------------------------------------------
	
	UPDATE @Log SET ExecTimeInMS = DATEDIFF_BIG(Millisecond, @TS, sysdatetime())

	SELECT ErrorCode, ExecTimeInMS, ReturnMsg FROM @Log
	SELECT UserID FROM @Ins

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
EXEC dbo.createUser '{
"UserName":"Alex",
"EmailAddress":"schmaus.a@gmail.com",
"FirstName":"Alex",
"LastName":"Schmaus"
}'

SELECT * FROM dbo.Users
SELECT TOP 1 * FROM Logging.SpLog ORDER BY RecordID DESC