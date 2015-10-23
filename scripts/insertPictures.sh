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
	WIDTH=`exiftool -ImageWidth "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	LENGTH=`exiftool -ImageHeight "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	BRENNWEITE=`exiftool -FocalLength "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	BLENDE=`exiftool -FNumber "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	EXPTIME=`exiftool -ExposureTime "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	DATETIME=`exiftool -DateTimeOriginal "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	PROGRAM=`exiftool -ExposureProgram "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	RESOLUTION_X=`exiftool -XResolution "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	RESOLUTION_Y=`exiftool -YResolution "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	META=`exiftool -ImageDescription "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	FOTOGRAPHER=`exiftool -Artist "$1" | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}'`
	TIMSTMP="`date +'%Y-%m-%d %H:%M:%S'`"

	DIRECTORY="`dirname 'data/2014.08.25_howe gelb/D800E_040396.jpg'`"
	CONCERTDATE=`basename "$DIRECTORY" | awk -F '_' '{print $1}' | sed 's/\./-/' | sed 's/\./-/'`
	CONCERTNAME=`basename "$DIRECTORY" | awk -F '_' '{print $2}'`

	echo "-------------------------------------";
	echo "FILENAME='$FILENAME'";
	echo "WIDTH='$WIDTH'";
	echo "LENGTH='$LENGTH'";
	echo "BRENNWEITE='$BRENNWEITE'";
	echo "BLENDE='$BLENDE'";
	echo "EXPTIME='$EXPTIME'";
	echo "DATETIME='$DATETIME'";
	echo "PROGRAM='$PROGRAM'";
	echo "RESOLUTION_X='$RESOLUTION_X'";
	echo "RESOLUTION_Y='$RESOLUTION_Y'";
	echo "META='$META'";
	echo "FOTOGRAPHER='$FOTOGRAPHER'";
	echo "TIMSTMP='$TIMSTMP'";
	echo "CONCERTDATE='$CONCERTDATE'";
	echo "CONCERTNAME='$CONCERTNAME'";

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename) SELECT id,'$BRENNWEITE','$BLENDE','$EXPTIME','$TIMSTMP','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPHER','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"
}

DATADIR=/data/ellokal.project-strus.net/
TIMSTMP="`date +'%y%m%d'`_`date +'%H%M%S'`"
LOGFILE="/var/log/ellokal/insert_exif_$TIMSTMP.log"
INPLIST="/var/log/ellokal/input_exif_$TIMSTMP.txt"
LASTUPD="$DATADIR/.lastUpdate"

if [ -f "$LASTUPD" ]; then
	find $DATADIR/[0-9]* -name "*.jpg" -cnewer $LASTUPD > $INPLIST
else
	find $DATADIR/[0-9]* -name "*.jpg" > $INPLIST
fi
while read filename <&3; do
	echo "+++ PROCESS $filename"
	processImage "$filename"
	# | psql --log-file="$LOGFILE" -d ellokal -h localhost -f-
done 3< $INPLIST
touch "$LASTUPD"




