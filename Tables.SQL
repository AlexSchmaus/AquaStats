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

DROP TABLE IF EXISTS Logging.SpLog

DROP TABLE IF EXISTS Readings.PH
DROP TABLE IF EXISTS Readings.Temperature
DROP TABLE IF EXISTS Readings.Ammonia
DROP TABLE IF EXISTS Readings.Nitrite
DROP TABLE IF EXISTS Readings.Nitrate
DROP TABLE IF EXISTS Readings.Alkalinity
DROP TABLE IF EXISTS Readings.GeneralHardness
DROP TABLE IF EXISTS Readings.Phosphate
DROP TABLE IF EXISTS Readings.TDS
DROP TABLE IF EXISTS Readings.Salinity

DROP TABLE IF EXISTS dbo.Aquariums
DROP TABLE IF EXISTS dbo.AquariumTypes
DROP TABLE IF EXISTS dbo.AquariumSizes
DROP TABLE IF EXISTS dbo.AquariumShapes
DROP TABLE IF EXISTS dbo.Users


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
VALUES	('Community Freshwater'),
		('Planted Tank'),
		('Blackwater'),
		('African Cichlid'),
		('Discus'),
		('Goldfish'),
		('Coldwater'),
		('Brackish'),
		('Community Saltwater'),
		('Reef'),
		('Coldwater Marine')
		

CREATE TABLE dbo.AquariumShapes (
	ShapeID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	ShapeName		varchar(128)	NOT NULL,
	)
INSERT INTO dbo.AquariumShapes
VALUES	('Rectangular'),			
		('Cube'),
		('Hexagonal'),
		('Octagonal'),
		('Bow Front'),
		('Cylindrical'),
		('Half Cylinder'),
		('Double Bullnose'),
		('Quater Cylinder'),
		('Triangular')


CREATE TABLE dbo.Aquariums (
	AquariumID		int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	UserID			int				NOT NULL	REFERENCES dbo.users(UserID),		-- who owns this aquarium?
	FriendlyName	varchar(256)	NULL,											-- like, "bedroom shrimp tank"
	AquariumVolume	float(24)		NULL,
	AquariumTypeID	int				NULL		REFERENCES dbo.AquariumTypes(TypeID)
	)
	
-------------------------------------------------------------------------------------------------------------------------------
-- Water Parameter readings
CREATE TABLE Readings.PH (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	PH				decimal(3,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Temperature (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Temperature		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)
	
CREATE TABLE Readings.Ammonia (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Ammonia			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrite (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrite			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrate			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Alkalinity ( -- aka Carbonate hardness 
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Alkalinity		decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.GeneralHardness (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	GeneralHardness decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Phosphate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Phosphate		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.tds (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	tds				decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Salinity (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Salinity		decimal(5,2)	NOT NULL,
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
