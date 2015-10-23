# ellokal_image_gallery

Bilder Gallery Online für das El Lokal

# Create tables
psql -f scripts/createTables.sql ellokal

# Update images
scripts/insertPictures.sh | psql ellokal

# Create strus search index
scripts/updateStrus.sh


