#!/bin/bash

imageTag() {
	exiftool "$1" | awk -F ':' '{gsub(/[ \t]+$/, "", $1); gsub(/^[ \t]+/, "", $2); print $1 "=" $2}' | grep "$1=" | awk -F'=' "/[=]/"'{print $2}' | head -n 1
}

thumbnail() {
	exiftool -b -ThumbnailImage "$1" > "$1.thumbnail.jpg"
	RES=`base64 "$1.thumbnail.jpg"` 
	rm -f "$1.thumbnail.jpg"
	echo $RES
}

processImage() {
	FILENAME=`echo "$1" | sed 's@/data/ellokal.project-strus.net/@@'`
	THUMBNAIL=`thumbnail "$1"`
	WIDTH=`imageTag "$1" "Exif Image Width"`
	LENGTH=`imageTag "$1" "Exif Image Height"`
	BRENNWEITE=`imageTag "$1" "Focal Length"`
	BLENDE=`imageTag "$1" "F-Number"`
	EXPTIME=`imageTag "$1" "Exposure Time"`
	DATETIME=`imageTag "$1" "Date and Time \(Origi" | sed 's/:/-/' | sed 's/:/-/'`
	PROGRAM=`imageTag "$1" "Exposure Program"`
	RESOLUTION_X=`imageTag "$1" "X Resolution"`
	RESOLUTION_Y=`imageTag "$1" "Y Resolution"`
	META=`imageTag "$1" "Image Description"`
	FOTOGRAPH=`imageTag "$1" "Artist"`
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
	echo "FOTOGRAPH='$FOTOGRAPH'";
	echo "TIMSTMP='$TIMSTMP'";
	echo "CONCERTDATE='$CONCERTDATE'";
	echo "CONCERTNAME='$CONCERTNAME'";

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename) SELECT id,'$BRENNWEITE','$BLENDE','$EXPTIME','$TIMSTMP','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPH','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"
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




