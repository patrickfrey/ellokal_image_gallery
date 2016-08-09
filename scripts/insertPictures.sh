#!/bin/bash

thumbnail() {
	exiftool -b -ThumbnailImage "$1" > "$1.thumbnail.jpg"
	RES=`base64 "$1.thumbnail.jpg"` 
	rm -f "$1.thumbnail.jpg"
	echo $RES
}

processImage() {
	FILENAME=`echo "$1" | sed 's@/data/ellokal.project-strus.net/@@'`
	THUMBNAIL=`thumbnail "$1"`
	WIDTH=`exiftool -ImageWidth "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	LENGTH=`exiftool -ImageHeight "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	BRENNWEITE=`exiftool -FocalLength "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	BLENDE=`exiftool -FNumber "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	EXPTIME=`exiftool -ExposureTime "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	DATETIME=`exiftool -DateTimeOriginal "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	PROGRAM=`exiftool -ExposureProgram "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	RESOLUTION_X=`exiftool -XResolution "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	RESOLUTION_Y=`exiftool -YResolution "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	META=`exiftool -ImageDescription "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	FOTOGRAPHER=`exiftool -Artist "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	TIMSTMP="`date +'%Y-%m-%d %H:%M:%S'`"

	DIRECTORY="`dirname 'data/2014.08.25_howe gelb/D800E_040396.jpg'`"
	CONCERTDATE=`basename "$DIRECTORY" | awk -F '_' '{print $1}' | sed 's/\./-/' | sed 's/\./-/'`
	CONCERTNAME=`basename "$DIRECTORY" | awk -F '_' '{print $2}'`

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename) SELECT id,'$BRENNWEITE','$BLENDE','$EXPTIME','$TIMSTMP','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPHER','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"
}

DATADIR=./data/images/
TIMSTMP="`date +'%y%m%d'`_`date +'%H%M%S'`"
INPLIST="./input_exif_$TIMSTMP.txt"
LASTUPD="$DATADIR/.lastUpdate"

if [ -f "$LASTUPD" ]; then
	find $DATADIR/[0-9]* -name "*.jpg" -cnewer $LASTUPD > $INPLIST
else
	find $DATADIR/[0-9]* -name "*.jpg" > $INPLIST
fi
while read filename <&3; do
	processImage "$filename"
done 3< $INPLIST

# LOGFILE="/var/log/ellokal/insert_exif_$TIMSTMP.log"
# | psql --log-file="$LOGFILE" -d ellokal -h localhost -f-
touch "$LASTUPD"


