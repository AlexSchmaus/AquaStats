USE AquaStats
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: A template to build SPs off of
--
-- 12/13/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [ ] Get started!

CREATE PROCEDURE dbo.ProcName
	@json varchar(4000)
AS BEGIN TRY
	SELECT 'Hello World'
	RETURN 0
END TRY
BEGIN CATCH
	RETURN 1
END CATCH
GO