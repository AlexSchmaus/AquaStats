USE AquaStats
GO

DROP FUNCTION IF EXISTS dbo.generateSalt
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: generates a salt for hashing PWs
--
-- 12/17/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ] 

CREATE FUNCTION dbo.generateSalt (
	@Length int
	)
RETURNS varchar(4000)
AS BEGIN
	DECLARE @i int = 1
	DECLARE @S varchar(4000)
	WHILE @i <= @Length BEGIN
		SET @S = concat(@S, (SELECT TOP 1 [Character] FROM dbo.RandomChar))
		SET @i = @i + 1
	END

	IF len(@S) != @Length RETURN NULL

	RETURN @S
	END
GO

SELECT 
	dbo.generateSalt(16),
	dbo.generateSalt(32),
	dbo.generateSalt(64)