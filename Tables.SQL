-------------------------------------------------------------------------------------------------------------------------------
--
-- Author: Alex Schmaus
-- Description: Tables / schema for AquaStats
--
-- 12/12/22		Alex	The start of something new!
-- 
-------------------------------------------------------------------------------------------------------------------------------

-- To Do:
-- [X] Get started!
-- [-] Figure out how to handle saltwater vs freswater, etc
-- [ ] Figure out how I want to handle timezones
-- [ ] Figure out how to handle non-rectangular tanks

/*
CREATE DATABASE AquaStats
GO
*/

USE AquaStats
GO

/*
-- First, Schemas
CREATE SCHEMA Logging
GO
CREATE SCHEMA Readings
GO
CREATE SCHEMA util
GO
*/

-- Create tables
CREATE TABLE dbo.users (
	UserID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	UserName		varchar(128)	NULL,		-- by default, emailAddress = UN
	EmailAddress	varchar(256)	NOT NULL	UNIQUE,
	FirstName		varchar(128)	NULL,
	LastName		varchar(128)	NULL,
	[Password]		varbinary(4000)	NOT NULL,
	Salt			binary(128)		NOT NULL
	)
CREATE UNIQUE NONCLUSTERED INDEX uq_dboUsers_UserName
ON dbo.Users(UserName)
WHERE UserName IS NOT NULL


CREATE TABLE dbo.AquariumTypes (
	TypeID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	FriendlyName	varchar(128)	NOT NULL
)
INSERT INTO dbo.AquariumTypes (FriendlyName)
VALUES	('Freshwater'),
		('Saltwater'),
		('Blackwater')	-- should this be a 'sub-type'?


CREATE TABLE dbo.AquariumSizes (
	SizeID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	FriendlyName	varchar(128)	NOT NULL,	
	LengthInches	decimal(8,2)	NOT NULL,				-- is decimal(8,2) too restrictive? Eh, can always ALTER it later if need be....
	WidthInches		decimal(8,2)	NOT NULL,
	HeightInches	decimal(8,2)	NOT NULL,				-- is doing this in inches a bad idea? Alternate would be, what? cm / mm ?
	VolumeGallons	decimal(8,2)	NOT NULL,				-- calculate in SP from user inputed L/W/H
	isStandard		bit				NOT NULL	DEFAULT 1	-- is this a standard size, or did a user manually enter it?
	)
INSERT INTO dbo.AquariumSizes (FriendlyName, LengthInches, WidthInches, HeightInches, VolumeGallons)
VALUES	('10 gallon', 20, 10, 12, 10),
		('20 gallon', 24, 12, 16, 20),
		('20 gallon long', 30, 12, 12, 20)


CREATE TABLE dbo.Aquariums (
	AquariumID		int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	UserID			int				NOT NULL	REFERENCES dbo.users(UserID),		-- who owns this aquarium?
	AquariumSizeID	int				NOT NULL	REFERENCES dbo.AquariumSizes(SizeID),
	AquariumTypeID	int				NULL		REFERENCES dbo.AquariumTypes(TypeID)
	)


-------------------------------------------------------------------------------------------------------------------------------
-- Water Parameter readings
DROP TABLE IF EXISTS Readings.PH
CREATE TABLE Readings.PH (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	PH				decimal(3,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Temperature
CREATE TABLE Readings.Temperature (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Temperature		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Ammonia
CREATE TABLE Readings.Ammonia (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Ammonia			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Nitrite
CREATE TABLE Readings.Nitrite (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrite			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Nitrate
CREATE TABLE Readings.Nitrate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrate			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Alkalinity
CREATE TABLE Readings.Alkalinity ( -- aka Carbonate hardness 
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Alkalinity		decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.GeneralHardness
CREATE TABLE Readings.GeneralHardness (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	GeneralHardness decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

DROP TABLE IF EXISTS Readings.Phosphate
CREATE TABLE Readings.Phosphate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Phosphate		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

-------------------------------------------------------------------------------------------------------------------------------
-- Logging, etc
-- DROP TABLE IF EXISTS Logging.SpLog
CREATE TABLE Logging.Splog (
	RecordID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	SpName			varchar(256)	NOT NULL,
	ErrorCode		int				NOT NULL,
	ExecTimeInMS	int				NULL,
	Parameter		varchar(4096)	NULL,		-- intended to be JSON
	ReturnMsg		varchar(4096)	NULL,		-- intended to be JSON
	AdditionalData	varchar(4096)	NULL,		-- intended to be JSON
	ProcessID		int				NULL,
	SpState			int				NULL,
	ExecAt			datetime		NOT NULL	-- Local Server time
	)
