-------------------------------------------------------------------------------------------------------------------------------
--
-- Author: Alex Schmaus
-- Description: Function to calculate volume of a tank, in gallons, from given dimensions
--
-- 12/12/22		Alex	The start of something new!
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ] Heh.... this assumes the tank is a perfect rectangle


CREATE FUNCTION dbo.CalcVolume (
	@L decimal(8,2),
	@W decimal(8,2)
	@H decimal(8,2)
	)
RETURNS decimal(8,2)
AS BEGIN

	-- one gallon is 231 cubic inches
	DECLARE @V = (@L * @W * @H) / 231

	RETURN @V

	END