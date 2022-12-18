USE AquaStats
GO

DROP FUNCTION IF EXISTS dbo.isBcrypt
GO

-------------------------------------------------------------------------------------------------------------------------------
--
-- Author:		Alex Schmaus
-- Description: Checks a string to see if it is a valid bCrypt hash or not. And, in particular if it is using BlowFish and
--					a 'strong' cost -> 10 or better. 
--				Return of 1 = the string is valid bCrypt. 0 = invalid
--
-- 12/18/22		Alex	init
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- Reference: https://en.wikipedia.org/wiki/Bcrypt

-- There's 4 segments in a bCrypt Hash:
 
-- $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
-- \__/\/ \____________________/\_____________________________/
-- Alg Cost      Salt                        Hash


-- (1) Algorithm Segment Definations:
--		$1$: MD5 algorithm
--		$2$: Blowfish algorithm 
--			$2$, $2a$, $2x$, $2y$, $2b$ are different versions
--		$sha1$: SHA-1 algorithm
--		$5$: SHA2-256 algorithm
--		$6$: SHA2-512 algorithm
-- (2) Cost: Number of rounds - 10 - 14 should be reasonbale
-- (3) Salt
-- (4) Hash of PW w/ Salt


CREATE FUNCTION dbo.isBcrypt (
	@STR varchar(128)
	)
RETURNS 
	bit 
AS BEGIN

	-- cleanup
	SET @STR = LTRIM(RTRIM(@STR))

	-- First char of the string should be a delimiter, the '$' char
	IF CHARINDEX('$', @STR) != 1 BEGIN
		RETURN 0
		END

	ELSE BEGIN
		-- Find all the delimiters in the hash
		DECLARE @D1 int = CHARINDEX('$', @STR)
		DECLARE @D2 int = CHARINDEX('$', @STR, @D1 + 1)
		DECLARE @D3 int = CHARINDEX('$', @STR, @D2 + 1)
		END

	-- Length - Should be 60, but the algorith segment can be varied in length
	IF LEN(@STR) NOT BETWEEN 58 AND 62 BEGIN 
		RETURN 0
		END

	-- Look for invalid characters in the hash
	ELSE IF @STR LIKE '%[!,@,#,%,^,&,*,(,),-,_,+,=,:,;]%' BEGIN
		RETURN 0
		END

	-- Check if the algorithm is Blowfish
	ELSE IF LEFT(@STR, 2) != '$2' BEGIN
		RETURN 0
		END

	-- Check Cost, a minimum we want a cost of 10
	ELSE IF SUBSTRING(@STR, @D2+1, @D3-@D2-1) < 10 BEGIN
		RETURN 0
		END
	
	-- Otherwise, its good!
	RETURN 1

END
GO

-- Quick Test --
SELECT 																								
	dbo.isBcrypt('$2a$12$UfzDBH7qJ.Z//zZXdhl3C.3y.Wfea0rVR8pqxY3/qgtmNOvumE0L6'),								-- Valid hash
	dbo.isBcrypt('$2b$10$//DXiVVE59p7G5k/4Klx/ezF7BI42QZKmoOD0NDvUuqxRE5bFFB'),									-- Also valid
	dbo.isBcrypt('password12345'),																				-- Clearly wrong
	dbo.isBcrypt('$2S8dFGkD7ii9pD'),																			-- Also totally wrong6
	dbo.isBcrypt('$2a$4$MTtOAXWq4W9SBTbux6ba5OE6c93pkD.O/x7siDY2MvMA5praSUybm'),								-- too few rounds
	dbo.isBcrypt('$2a$12$MTtOAXWq4W9SBTbux6balsdkjgsjamoj32456mfdm5OE6c93pkD.O/x7sisdfsdffhDY2MvMA5praSUybm'),	-- too long
	dbo.isBcrypt('$2y$10$jqBk#O'),																				-- too short
	dbo.isBcrypt('$1$12$vgKhxo9gxC7/wzc04OPR2OcPc2b9cCunyby6hIgMuKtauHDVhpT2G')									-- Out of data algorithm (MD5)