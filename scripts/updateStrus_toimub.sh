#!/bin/bash

getPictureXmlSelect() {
	echo "SELECT xmlelement(name item, xmlforest(ConcertPicture.id AS \"id\",ConcertPicture.concertId AS \"concertid\", Concert.title AS \"title\", ConcertPicture.focaldist AS \"focaldist\", ConcertPicture.apperture AS \"apperture\", ConcertPicture.shutterspeed AS \"shutterspeed\", ConcertPicture.insertdate AS \"insertdate\", ConcertPicture.eventdate AS \"eventdate\", ConcertPicture.program AS \"program\", ConcertPicture.resolution_X AS \"resolution_X\", ConcertPicture.resolution_Y AS \"resolution_Y\", ConcertPicture.width AS \"width\", ConcertPicture.length AS \"length\", ConcertPicture.meta AS \"meta\", ConcertPicture.fotographer AS \"fotographer\", ConcertPicture.thumbnail AS \"thumbnail\", ConcertPicture.filename AS \"filename\")) FROM ConcertPicture INNER JOIN Concert ON Concert.id=ConcertPicture.concertId;"
}
getConcertXmlSelect() {
	echo "SELECT xmlelement(name item, xmlforest(Concert.id AS \"id\", Concert.title AS \"title\")) FROM Concert;"
}

getPictureXml() {
	echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	echo '<list>'
	getPictureXmlSelect "$1" | psql --tuples-only -U ellokal -d ellokaldb -h localhost -f-
	echo '</list>'
}

getConcertXml() {
	echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	echo '<list>'
	getConcertXmlSelect "$1" | psql --tuples-only -U ellokal -d ellokaldb -h localhost -f-
	echo '</list>'
}


getPictureXml > "./data/insert_picture.xml"
getConcertXml > "./data/insert_concert.xml"
strusDestroy -s "path=data/storage"
strusDestroy -s "path=data/storage_dym"
strusCreate -s "path=data/storage; metadata=pictureno UINT32, concertid UINT16, doclen UINT16, minpos_title UINT8, maxpos_title UINT8; cache=256M"
strusCreate -s "path=data/storage_dym; cache=256M"
strusInsert -s "path=data/storage" -L "./data/insert_picture.log" -c 20000 config/pictures.ana "./data/insert_picture.xml"
strusInsert -s "path=data/storage_dym" -L "./data/insert_concert.log" -c 20000 config/concerts.ana "./data/insert_concert.xml"



