USE AquaStats
GO

DROP VIEW IF EXISTS dbo.RandomDigit
DROP VIEW IF EXISTS dbo.RandomChar					
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: generates random character
--
-- 12/17/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

CREATE VIEW dbo.RandomChar (
	[Character]
	) AS 
	
SELECT 
	CHOOSE(
		(SELECT TOP 1 Number FROM util.numbers WHERE Number BETWEEN 1 AND 3 ORDER BY newid()),
		-- ASCII: A = 65, Z = 90
		CHAR(FLOOR(RAND()*(91-65)+65)),
		-- ASCII: a = 97, z = 122
		CHAR(FLOOR(RAND()*(123-97)+97)),
		-- ASCII: 0 = 48, 9 = 57
		CHAR(FLOOR(RAND()*(58-48)+48))
		)
	-- FLOOR(RAND()*(Y-X)+X)) will generate a number, z, where: X <= Z < Y
	--	Therefore, to get a number between A and B, one would set X = A and Y = B + 1

GO

SELECT * FROM dbo.RandomChar
GO


SELECT TOP 1 Number FROM util.numbers WHERE Number BETWEEN 1 AND 3 ORDER BY newid()