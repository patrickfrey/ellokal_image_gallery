#!/bin/bash

getPictureXmlSelect() {
	echo "SELECT xmlelement(name item, xmlforest(ConcertPicture.id AS \"id\",ConcertPicture.concertId AS \"concertid\", Concert.title AS \"title\", ConcertPicture.focaldist AS \"focaldist\", ConcertPicture.apperture AS \"apperture\", ConcertPicture.shutterspeed AS \"shutterspeed\", ConcertPicture.insertdate AS \"insertdate\", ConcertPicture.eventdate AS \"eventdate\", ConcertPicture.program AS \"program\", ConcertPicture.resolution_X AS \"resolution_X\", ConcertPicture.resolution_Y AS \"resolution_Y\", ConcertPicture.width AS \"width\", ConcertPicture.length AS \"length\", ConcertPicture.meta AS \"meta\", ConcertPicture.fotographer AS \"fotographer\", ConcertPicture.thumbnail AS \"thumbnail\", ConcertPicture.filename AS \"filename\")) FROM ConcertPicture INNER JOIN Concert ON Concert.id=ConcertPicture.concertId;"
}

getPictureXml() {
	echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	echo '<list>'
	getPictureXmlSelect "$1" | psql --tuples-only -U ellokal -d ellokaldb -h localhost -f-
	echo '</list>'
}

LOGFILE="./data/insert_picture.log"
INPFILE="./data/insert_picture.xml"

getPictureXml > $INPFILE
strusDestroy -s "path=data/storage"
strusCreate -s "path=data/storage; metadata=insertdate UINT32, eventdate UINT32, concertid UINT16, doclen UINT16, minpos_title UINT8, maxpos_title UINT8; cache=256M"
strusInsert -s "path=data/storage" -L "$LOGFILE" -c 20000 config/pictures.ana $INPFILE



