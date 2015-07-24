CREATE TABLE Contributor
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	firstname	TEXT	NOT NULL,
	surname		TEXT	NOT NULL,
	username	TEXT	NOT NULL,
	pwhash		TEXT	NOT NULL
);

CREATE TABLE Note
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	contributorid	INT REFERENCES Contributor(id),
	content_en	TEXT,
	content_de	TEXT
);

CREATE TABLE Artist
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	firstname	TEXT	NOT NULL,
	surname		TEXT	NOT NULL,
	birth		TIMESTAMP,
	rip		TIMESTAMP,
	country		TIMESTAMP,
	description_en	TEXT,
	description_de	TEXT
);

CREATE TABLE Band
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	name		TEXT	NOT NULL,
	description_en	TEXT,
	description_de	TEXT
);

CREATE TABLE Concert
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	date		TIMESTAMP,
	title		TEXT,
	description_en	TEXT,
	description_de	TEXT
);

CREATE TABLE ConcertBandArtistRelation
(
	concertId	INT REFERENCES Concert(id),
	bandId		INT REFERENCES Band(id),
	artistId	INT REFERENCES Artist(id)
);

CREATE TABLE ConcertPicture
(
	id		SERIAL	NOT NULL PRIMARY KEY,
	concertId	INT REFERENCES Concert(id),
	date		TIMESTAMP,
	description_en	TEXT,
	description_de	TEXT,
	dim_X		INT,
	dim_Y		INT,
	brennweite	TEXT,
	blende		TEXT,
	verschlusszeit	TEXT,
	program		TEXT,
	resolution_X	FLOAT4,
	resolution_Y	FLOAT4,
	width		INT,
	length		INT,
	meta		TEXT,
	fotograph	TEXT,
	thumbnail	TEXT,
	filename	TEXT
);



