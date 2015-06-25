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
	description_en	TEXT,
	description_de	TEXT
	thumbnail	TEXT
);

CREATE TABLE ConcertPictureBlob
(
	concertId	INT PRIMARY KEY REFERENCES Concert(id),
	data		BLOB
);


