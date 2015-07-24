# Docker image for the El Lokal (Zürich) image gallery:
# -----------------------------------------------------

FROM patrickfrey/strus-ub1404-pqnx
MAINTAINER patrickpfrey@yahoo.com

# Prerequisites:
# --------------
# Install:
#	exif = image meta data extraction by command line
RUN apt-get update \
 && apt-get -y --force-yes install \
	exif

# Entrypoint:
COPY ./entrypoint.sh /srv/entrypoint.sh

# El Lokal database:
# ------------------
# VOLUME /var/log/ellokal
RUN mkdir -p /var/log/ellokal
RUN chown strus:strus /var/log/ellokal
USER strus
WORKDIR /home/strus
COPY ./createDatabase.sql /home/strus/createDatabase.sql
COPY ./createTables.sql /home/strus/createTables.sql
COPY ./insertPictures.sh /home/strus/insertPictures.sh
RUN echo "localhost:*:ellokaldb:strus:strus" > /home/strus/.pgpass
RUN chmod 0600 /home/strus/.pgpass
ENV PGPASSFILE=/home/strus/.pgpass

USER root
RUN /etc/init.d/postgresql start &&\
	sudo su - strus -c "psql -U strus -f /home/strus/createDatabase.sql" &&\
	sudo su - strus -c "psql -U strus -d ellokaldb -f /home/strus/createTables.sql"

# Web server:
# -----------
USER root
WORKDIR /etc/nginx
ENTRYPOINT ["/srv/entrypoint.sh"]
CMD ["nginx"]
EXPOSE 80

# Permissions for start in shell:
# -------------------------------
WORKDIR /home/strus
USER root


