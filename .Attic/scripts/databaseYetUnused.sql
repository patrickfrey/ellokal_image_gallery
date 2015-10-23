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
	languageid	INT REFERENCES Language(id),
	contributorid	INT REFERENCES Contributor(id),
	content_en	TEXT,
	content_de	TEXT
);

