# ellokal_image_gallery

Bilder Gallery Online für das El Lokal

# Create tables
psql -f scripts/dropTables.sql
psql -f scripts/createTables.sql

# Update images
scripts/insertZip.sh <archive file - mischa> | psql ellokal -f -

# Create strus search index
scripts/updateStrus_toimub.sh

