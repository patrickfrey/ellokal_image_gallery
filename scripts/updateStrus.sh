#!/bin/bash

getPictureXmlSelect() {
	TIMSTMP="$1"

	# echo "SELECT Concert.title,ConcertPicture.concertId,ConcertPicture.brennweite,ConcertPicture.blende,ConcertPicture.verschlusszeit,ConcertPicture.insertdate,ConcertPicture.eventdate,ConcertPicture.program,ConcertPicture.resolution_X,ConcertPicture.resolution_Y,ConcertPicture.width,ConcertPicture.length,ConcertPicture.meta,ConcertPicture.fotograph,ConcertPicture.thumbnail,ConcertPicture.filename FROM ConcertPicture INNER JOIN Concert ON Concert.id=ConcertPicture.concertId WHERE ConcertPicture.insertdate >= '$TIMSTMP';"
	echo "SELECT xmlelement(name item, xmlforest(ConcertPicture.id AS \"id\",ConcertPicture.concertId AS \"concertid\", Concert.title AS \"title\", ConcertPicture.brennweite AS \"brennweite\", ConcertPicture.blende AS \"blende\", ConcertPicture.verschlusszeit AS \"verschlusszeit\", ConcertPicture.insertdate AS \"insertdate\", ConcertPicture.eventdate AS \"eventdate\", ConcertPicture.program AS \"program\", ConcertPicture.resolution_X AS \"resolution_X\", ConcertPicture.resolution_Y AS \"resolution_Y\", ConcertPicture.width AS \"width\", ConcertPicture.length AS \"length\", ConcertPicture.meta AS \"meta\", ConcertPicture.fotograph AS \"fotograph\", ConcertPicture.thumbnail AS \"thumbnail\", ConcertPicture.filename AS \"filename\")) FROM ConcertPicture INNER JOIN Concert ON Concert.id=ConcertPicture.concertId WHERE ConcertPicture.insertdate >= '$TIMSTMP';"
}

getPictureXml() {
	echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
	echo '<list>'
	getPictureXmlSelect "$1" | psql --tuples-only -U strus -d ellokaldb -h localhost -f-
	echo '</list>'
}

TIMSTMP=$1
if [ x"$TIMSTMP" = "x" ]; then
	TIMSTMP=`date +%Y-%m-%d`
fi

FSTMP="`date +'%y%m%d'`_`date +'%H%M%S'`"
LOGFILE="/var/log/ellokal/insert_picture_$FSTMP.log"
INPFILE="/var/log/ellokal/indert_picture_$FSTMP.xml"
CONFIGDIR=/home/patrick/Projects/github/ellokal_image_gallery/config

getPictureXml $TIMSTMP > $INPFILE
strusCreate -S $CONFIGDIR/storage.conf
strusInsert -S $CONFIGDIR/storage.conf -L "$LOGFILE" -c 20000 $CONFIGDIR/pictures.ana $INPFILE



