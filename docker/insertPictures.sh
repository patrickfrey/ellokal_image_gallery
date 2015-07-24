#!/bin/bash

imageTag() {
	exif "$1" | awk -F '|' '{gsub(/[ \t]+$/, "", $1); print $1 "=" $2}' | awk -F'=' "/$2[=]/"'{print $2}' | head -n 1
}

thumbnail() {
	exif -e "$1" > /dev/null
	RES=`base64 "$1.modified.jpeg"` 
	rm -f "$1.modified.jpeg"
	echo $RES
}

processImage() {
	FILENAME=`echo "$1" | sed 's@/srv/ellokal/@@'`
	THUMBNAIL=`thumbnail "$1"`
	DIM_X=`imageTag "$1" "Pixel X Dimension"`
	DIM_Y=`imageTag "$1" "Pixel Y Dimension"`
	BRENNWEITE=`imageTag "$1" "Focal Length"`
	BLENDE=`imageTag "$1" "F-Number"`
	EXPTIME=`imageTag "$1" "Exposure Time"`
	DATETIME=`imageTag "$1" "Date and Time \(Origi" | sed 's/:/-/' | sed 's/:/-/'`
	PROGRAM=`imageTag "$1" "Exposure Program"`
	RESOLUTION_X=`imageTag "$1" "X-Resolution"`
	RESOLUTION_Y=`imageTag "$1" "Y-Resolution"`
	WIDTH=`imageTag "$1" "Image Width"`
	LENGTH=`imageTag "$1" "Image Length"`
	META=`imageTag "$1" "Image Description"`
	FOTOGRAPH=`imageTag "$1" "Artist"`

	DIRECTORY="`dirname 'data/2014.08.25_howe gelb/D800E_040396.jpg'`"
	CONCERTDATE=`basename "$DIRECTORY" | awk -F '_' '{print $1}' | sed 's/\./-/' | sed 's/\./-/'`
	CONCERTNAME=`basename "$DIRECTORY" | awk -F '_' '{print $2}'`

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,dim_X,dim_Y,brennweite,blende,verschlusszeit,date,program,resolution_X,resolution_Y,width,length,meta,fotograph,thumbnail,filename) SELECT id,'$DIM_X','$DIM_Y','$BRENNWEITE','$BLENDE','$EXPTIME','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPH','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"

	# echo "THUMBNAIL=$THUMBNAIL"
	# echo "DIM_X=$DIM_X"
	# echo "DIM_Y=$DIM_Y"
	# echo "BRENNWEITE=$BRENNWEITE"
	# echo "BLENDE=$BLENDE"
	# echo "EXPTIME=$EXPTIME"
	# echo "DATETIME=$DATETIME"
	# echo "PROGRAM=$PROGRAM"
	# echo "RESOLUTION_X=$RESOLUTION_X"
	# echo "RESOLUTION_Y=$RESOLUTION_Y"
	# echo "WIDTH=$WIDTH"
	# echo "LENGTH=$LENGTH"
	# echo "META=$META"
	# echo "FOTOGRAPH=$FOTOGRAPH"
}

# if [ -f "/srv/ellokal/.lastUpdate" ]; then
# 	find /srv/ellokal/[0-9]* -name "*.jpg" -cnewer /srv/ellokal/.lastUpdate | xargs processImage
# else
# 	find /srv/ellokal/[0-9]* -name "*.jpg" | xargs processImage
# fi
# touch /srv/ellokal/.lastUpdate

processImage '/srv/ellokal/2014.08.25_howe gelb/D800E_040349.jpg' | psql -U strus -d ellokaldb -h localhost -f-



