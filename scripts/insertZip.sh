#!/bin/bash

thumbnail() {
	exiftool -b -ThumbnailImage "$1" > "$1.thumbnail.jpg"
	RES=`base64 "$1.thumbnail.jpg"` 
	rm -f "$1.thumbnail.jpg"
	echo $RES
}
PICTURECNT=0

processImage() {
	FILENAME=`echo "$1" | perl -pe 's@^.*/([A-F0-9_]+).jpg$@\1@' | perl -pe "s@\'([\S])@\'\'\1@g"`
	CONCERTDATE=`echo "$1" | grep -oP "[0-9]{4}[\.][0-9]{1,2}[\.][0-9]{1,2}" | sed 's/04\.31/04\.30/'`
	PICTURECNT=$(expr $PICTURECNT + 1)
	exiftool "$1" > exiftool.out
	CONCERTNAME=`cat exiftool.out | grep '^Title\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	THUMBNAIL=`thumbnail "$1"`
	WIDTH=`cat exiftool.out | grep '^Image Width\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	RESIZEIMG_100="28%"
	RESIZEIMG_60="17%"
	RESIZEIMG_45="13%"
	RESIZEIMG_30="8%"
	if [ $WIDTH -gt 7000 ]; then
		RESIZEIMG_100="12%";
		RESIZEIMG_60="7%"
		RESIZEIMG_45="5%"
		RESIZEIMG_30="4%"
	elif [ $WIDTH -gt 6000 ]; then
		RESIZEIMG_100="16%";
		RESIZEIMG_60="10%"
		RESIZEIMG_45="7%"
		RESIZEIMG_30="5%"
	elif [ $WIDTH -gt 5000 ]; then
		RESIZEIMG_100="20%";
		RESIZEIMG_60="12%"
		RESIZEIMG_45="9%"
		RESIZEIMG_30="6%"
	elif [ $WIDTH -gt 4000 ]; then
		RESIZEIMG_100="24%";
		RESIZEIMG_60="14%"
		RESIZEIMG_45="11%"
		RESIZEIMG_30="7%"
	fi
	VIEWIMG_100=`convert -resize $RESIZEIMG_100 "$1" - | composite -geometry +20+20 -blend 15 ../../scripts/logoellokal_20p.png - - | base64 -`
	VIEWIMG_60=`convert -resize $RESIZEIMG_60 "$1" - | composite -geometry +20+20 -blend 12 ../../scripts/logoellokal_12p.png - - | base64 -`
	VIEWIMG_45=`convert -resize $RESIZEIMG_45 "$1" - | composite -geometry +20+20 -blend 12 ../../scripts/logoellokal_9p.png - - | base64 -`
	VIEWIMG_30=`convert -resize $RESIZEIMG_30 "$1" - | composite -geometry +20+20 -blend 12 ../../scripts/logoellokal_6p.png - - | base64 -`
	LENGTH=`cat exiftool.out | grep '^Image Height\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	BRENNWEITE=`cat exiftool.out | grep '^Focal Length\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	BLENDE=`cat exiftool.out | grep '^F Number\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	EXPTIME=`cat exiftool.out | grep '^Exposure Time\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	DATETIME=`cat exiftool.out | grep '^Date/Time Original\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	PROGRAM=`cat exiftool.out | grep '^Exposure Program\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	RESOLUTION_X=`cat exiftool.out | grep '^X Resolution\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	RESOLUTION_Y=`cat exiftool.out | grep '^Y Resolution\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	META=`cat exiftool.out | grep '^Keywords\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	FOTOGRAPHER=`cat exiftool.out | grep '^Artist\s*[:]' | head -n 1 | awk '{sub(/:/,"~")}1' | awk -F'~' '{print $2}' | sed 's/^ //' | perl -pe "s@\'([\S])@\'\'\1@g"`
	TIMSTMP="`date +'%Y-%m-%d %H:%M:%S'`"

	echo "INSERT INTO Concert (date,title) SELECT '$CONCERTDATE', '$CONCERTNAME' WHERE NOT EXISTS (SELECT * FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME');"
	echo "INSERT INTO ConcertPicture (concertId,focaldist,apperture,shutterspeed,insertdate,eventdate,program,resolution_X,resolution_Y,width,length,meta,fotographer,thumbnail,filename) SELECT id,'$BRENNWEITE','$BLENDE','$EXPTIME','$TIMSTMP','$DATETIME','$PROGRAM','$RESOLUTION_X','$RESOLUTION_Y','$WIDTH','$LENGTH','$META','$FOTOGRAPHER','$THUMBNAIL','$FILENAME' FROM Concert WHERE date='$CONCERTDATE' AND title='$CONCERTNAME';"
	echo "INSERT INTO ConcertPictureImg (pictureId,size,image) SELECT id,'100','$VIEWIMG_100' FROM ConcertPicture WHERE filename='$FILENAME';"
	echo "INSERT INTO ConcertPictureImg (pictureId,size,image) SELECT id,'60','$VIEWIMG_60' FROM ConcertPicture WHERE filename='$FILENAME';"
	echo "INSERT INTO ConcertPictureImg (pictureId,size,image) SELECT id,'45','$VIEWIMG_45' FROM ConcertPicture WHERE filename='$FILENAME';"
	echo "INSERT INTO ConcertPictureImg (pictureId,size,image) SELECT id,'30','$VIEWIMG_30' FROM ConcertPicture WHERE filename='$FILENAME';"
}

rm -Rf tmp
if [[ $1 =~ ^http ]]; then
	mkdir -p tmp
	cd tmp
	wget $1
	ZIPNAME=`basename *.zip ".zip"`
else
	ZIPNAME=`basename "$1" ".zip"`
	mkdir -p tmp
	cp "$1" tmp/
	cd tmp
fi
unzip *.zip
rm -Rf __MACOSX
find "./" -name "*.jpg" | sort > input.lst

while read filename <&3; do
	processImage "$filename"
done 3< input.lst > "../$ZIPNAME.sql"
cd ..
rm -Rf tmp




