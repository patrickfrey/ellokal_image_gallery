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
COPY ./strus_storage.conf /etc/strus/storage.conf
COPY ./createDatabase.sql /home/strus/createDatabase.sql
COPY ./createTables.sql /home/strus/createTables.sql
COPY ./insertPictures.sh /home/strus/insertPictures.sh
COPY ./updateStrus.sh /home/strus/updateStrus.sh
COPY ./pictures.ana /home/strus/pictures.ana
COPY ./query.ana /home/strus/query.ana
COPY ./query.eva /home/strus/query.eva
COPY ./query.qln /home/strus/query.qln

RUN echo "localhost:*:ellokaldb:strus:strus" > /home/strus/.pgpass
RUN chmod 0600 /home/strus/.pgpass
ENV PGPASSFILE=/home/strus/.pgpass

USER root
RUN /etc/init.d/postgresql start &&\
	sudo su - strus -c "psql -U strus -f /home/strus/createDatabase.sql" &&\
	sudo su - strus -c "psql -U strus -d ellokaldb -f /home/strus/createTables.sql"


# Strus server:
# -------------
USER strus
ENTRYPOINT ["/srv/entrypoint.sh"]
CMD ["strusRpcServer", "-c", "-S", "/etc/strus/storage.conf"]

# Permissions for start in shell:
# -------------------------------
WORKDIR /home/strus
USER root

# Mapped ports:
# -------------
EXPOSE 80

