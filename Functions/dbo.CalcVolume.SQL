USE AquaStats
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author: Alex Schmaus
-- Description: Function to calculate volume of a tank, in gallons, from given dimensions
--
-- 12/12/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ] Heh.... this assumes the tank is a perfect rectangle

CREATE FUNCTION dbo.CalcVolume (
	@L decimal(8,2),
	@W decimal(8,2),
	@H decimal(8,2)
	)
RETURNS decimal(8,2)
AS BEGIN
	-- one gallon is 231 cubic inches
	DECLARE @V decimal(8,2) = (@L * @W * @H) / 231
	RETURN @V
	END
GO

SELECT 
	dbo.CalcVolume(30, 12, 12),	-- these are the deminsions for a 20 gal long, so this should return 20
	dbo.CalcVolume(20, 10, 12),	-- 10 gallon tank
	dbo.CalcVolume(36, 18, 19)	-- 50 gallon

-- huh.. these are all slightly off.... reutrns 18.7, 10.4, 53.3
--	I wonder if this is my math OR if this is just how it is, and
--	people colloquially refer to 18.7 as 20, etc