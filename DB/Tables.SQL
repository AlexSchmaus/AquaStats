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


CREATE DATABASE AquaStats
GO

USE AquaStats
GO


-- First, Schemas
CREATE SCHEMA Logging
GO
CREATE SCHEMA Readings
GO

-- Create tables
CREATE TABLE dbo.users (
	UserID			int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	EmailAddress	varchar(256)	NOT NULL	UNIQUE,
	FirstName		varchar(128)	NULL,
	LastName		varchar(128)	NULL
	)
INSERT INTO dbo.Users (EmailAddress, FirstName, LastName)
VALUES ('schmaus.a@gmail.com', 'Alex', 'Schmaus')


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
	LengthInches	decimal(8,2)	NOT NULL,
	WidthInches		decimal(8,2)	NOT NULL,
	HeightInches	decimal(8,2)	NOT NULL,
	VolumeGallons	decimal(8,2)	NOT NULL	-- calculate in SP from user inputed L/W/H
	)
INSERT INTO dbo.AquariumSizes (FriendlyName, LengthInces, WidthInches, HeightInches, VolumeGallons)
VALUES	('10 gallon', , , , ),
		('20 gallon', , , , ),
		('20 gallon long', , , , )


CREATE TABLE dbo.Aquariums (
	AquariumID		int				NOT NULL	IDENTITY(1,1)	PRIMARY KEY,
	UserID			int				NOT NULL	REFERENCES dbo.users(UserID),		-- who owns this aquarium?
	AquariumSizeID	int				NOT NULL	REFERENCES dbo.AquariumSizes(AquariumSizeID),
	AquariumTypeID	int				NOT			REFERENCES dbo.AquariumTypes(AquariumTypeID),
	)
INSERT INTO dbo.Aquariums (UserID, AquariumSizeID, AquariumType)
SELECT 1, 3, 1	-- Alex schmaus has a 20 gallon long Freshwater



-------------------------------------------------------------------------------------------------------------------------------
-- Water Parameter readings
CREATE TABLE Readings.PH (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.Temperature (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.Ammonia (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrite (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.Nitrate (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.Alkalinity ( -- aka Carbonate hardness 
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)

CREATE TABLE Readings.GeneralHardness (
	ID				bigint			NOT NULL	IDENITY(1,1)	PRIMARY KEY,
	AquriumID		int				NOT NULL	REFERENCES dbo.Aquariums(AquariumID),
	TimeStamp		datetime		NOT NULL	
	)