USE AquaStats
GO

DROP TYPE IF EXISTS SpLog
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: tabular data type to help ease logging
--
-- 12/13/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------


CREATE TYPE SpLog AS TABLE (
	SpName			varchar(256)	NOT NULL,
	ExecTimeInMS	int				NULL,
	Parameter		varchar(4096)	NULL,		-- intended to be JSON
	ReturnMsg		varchar(4096)	NULL,		-- intended to be JSON
	AdditionalData	varchar(4096)	NULL,		-- intended to be JSON
	ProcessID		int				NULL,
	SpState			int				NULL,
	ExecAt			datetime		NOT NULL	-- Local Server time
	)
GO