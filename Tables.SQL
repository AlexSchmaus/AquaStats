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
-- [-] Figure out how to handle non-rectangular tanks

-------------------------------------------------------------------------------------------------------------------------------
-- Create the DB!
-------------------------------------------------------------------------------------------------------------------------------

/*
CREATE DATABASE AquaStats
GO
*/

USE AquaStats
GO

-------------------------------------------------------------------------------------------------------------------------------
-- First, Create Schemas
-------------------------------------------------------------------------------------------------------------------------------

/*
CREATE SCHEMA Logging
GO
CREATE SCHEMA Readings
GO
CREATE SCHEMA util
GO
*/

-------------------------------------------------------------------------------------------------------------------------------
-- Cleanup existing
--	Since this is not up and running anywhere in production, I can drop tables & remake them. Once the DB goes into prod, 
--	this will be an no-go
-------------------------------------------------------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------------------------------------------------------
-- Create tables
-------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE dbo.users (
	UserID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	UserName		varchar(128)	NULL,		-- by default, emailAddress = UN
	EmailAddress	varchar(256)	NOT NULL	UNIQUE,
	FirstName		varchar(128)	NULL,
	LastName		varchar(128)	NULL,
	[Password]		varbinary(4000)	NOT NULL,
	Salt			binary(128)		NOT NULL
	)
-- By default UserName is the user's email address. UserName is optional. Therefore, we cannot add
--	a unique contstraint to UserName, as NULL across more then one would violate this
CREATE UNIQUE NONCLUSTERED INDEX uq_dboUsers_UserName
ON dbo.Users(UserName)
WHERE UserName IS NOT NULL


CREATE TABLE dbo.AquariumTypes (
	TypeID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	FriendlyName	varchar(128)	NOT NULL
)
INSERT INTO dbo.AquariumTypes (FriendlyName)
VALUES	('Community Freshwater'),	-- 1
		('Planted Tank'),			-- 2
		('Blackwater'),				-- 3
		('African Cichlid'),		-- 4
		('Discus'),					-- 5
		('Goldfish'),				-- 6
		('Coldwater'),				-- 7
		('Brackish'),				-- 8
		('Community Saltwater'),	-- 9
		('Reef'),					-- 10
		('Coldwater Marine')		-- 11
		

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
	AquariumVolume	float(24)		NULL,											-- Size of the aquarium, in Gallons
	AquariumTypeID	int				NULL		REFERENCES dbo.AquariumTypes(TypeID),
	isDeleted		bit				NOT NULL	DEFAULT 0
	)
	
-------------------------------------------------------------------------------------------------------------------------------
-- Water Parameter readings
CREATE TABLE Readings.PH (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	PH				decimal(3,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Temperature (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Temperature		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)
	
CREATE TABLE Readings.Ammonia (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Ammonia			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrite (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrite			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Nitrate			decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Alkalinity ( -- aka Carbonate hardness 
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Alkalinity		decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.GeneralHardness (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	GeneralHardness decimal(7,1)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Phosphate (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Phosphate		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.tds (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	tds				decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)

CREATE TABLE Readings.Salinity (
	ReadingID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	AquariumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	Salinity		decimal(5,2)	NOT NULL,
	[TimeStamp]		datetime		NOT NULL	
	)


-------------------------------------------------------------------------------------------------------------------------------
-- Logging, etc
CREATE TABLE Logging.Splog (
	RecordID		bigint			NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	SpName			varchar(256)	NOT NULL,
	ErrorCode		int				NOT NULL,
	ExecTimeInMS	int				NULL,
	Parameter		varchar(4096)	NULL,		-- intended to be JSON
	ReturnMsg		varchar(4096)	NULL,		
	AdditionalData	varchar(4096)	NULL,		-- intended to be JSON
	ProcessID		int				NULL,
	SpState			int				NULL,
	ExecAt			datetime		NOT NULL	-- Local Server time
	)
