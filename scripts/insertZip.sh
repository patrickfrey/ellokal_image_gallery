#!/bin/bash

thumbnail() {
	exiftool -b -ThumbnailImage "$1" > "$1.thumbnail.jpg"
	RES=`base64 "$1.thumbnail.jpg"` 
	rm -f "$1.thumbnail.jpg"
	echo $RES
}

processImage() {
	FILENAME=`echo "$1" | sed 's@^[\/0-9A-Za-z\ \.\-\_]*/@@' | sed 's/.jpg$//'`
	CONCERTDATE=`echo "$1" | grep -oP "[0-9]{4}[\.][0-9]{1,2}[\.][0-9]{1,2}"`
	EXIFCONTENT=`exiftool "$1"`
	CONCERTNAME=`echo $EXIFCONTENT | grep '^Title\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	THUMBNAIL=`thumbnail "$1"`
	WIDTH=`echo $EXIFCONTENT | grep '^Image Width\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	LENGTH=`echo $EXIFCONTENT | grep '^Image Height\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	BRENNWEITE=`echo $EXIFCONTENT | grep '^Focal Length\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	BLENDE=`echo $EXIFCONTENT | grep '^F Number\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	EXPTIME=`echo $EXIFCONTENT | grep '^Exposure Time\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	DATETIME=`echo $EXIFCONTENT | grep '^Date/Time Original\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	PROGRAM=`echo $EXIFCONTENT | grep '^Exposure Program\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	RESOLUTION_X=`echo $EXIFCONTENT | grep '^X Resolution\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	RESOLUTION_Y=`echo $EXIFCONTENT | grep '^Y Resolution\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	META=`echo $EXIFCONTENT | grep '^Keywords\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	FOTOGRAPHER=`echo $EXIFCONTENT | grep '^Artist\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //'`
	TIMSTMP="`date +'%Y-%m-%d %H:%M:%S'`"

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename) SELECT id,'$BRENNWEITE','$BLENDE','$EXPTIME','$TIMSTMP','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPHER','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"
}

if [[ $1 =~ ^http ]]; then
	mkdir -p tmp
	cd tmp
	wget $1
	ZIPNAME=`basename *.zip ".zip"`
else
	ZIPNAME=`basename "$1" ".zip"`
	mkdir -p tmp
	cp $1 tmp/
	cd tmp
fi
unzip *.zip
rm -Rf __MACOSX
find "./" -name "*.jpg" > input.lst

while read filename <&3; do
	processImage "$filename"
done 3< input.lst > "../$ZIPNAME.sql"
cd ..
rm -Rf tmp




