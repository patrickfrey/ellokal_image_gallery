# Docker image for the El Lokal (Zürich) image gallery:
# -----------------------------------------------------

FROM patrickfrey/strus-ub1404-pqnx
MAINTAINER patrickpfrey@yahoo.com

COPY ./entrypoint.sh /srv/entrypoint.sh

# El Lokal database:
# ------------------
USER strus
WORKDIR /home/strus
COPY ./createDatabase.sql /home/strus/createDatabase.sql
COPY ./createTables.sql /home/strus/createTables.sql

USER root
RUN /etc/init.d/postgresql start &&\
	sudo su - strus -c "psql -f /home/strus/createDatabase.sql" &&\
	sudo su - strus -c "psql -f /home/strus/createTables.sql"


# Web server:
# -----------
USER root
WORKDIR /etc/nginx
ENTRYPOINT ["/srv/entrypoint.sh"]
CMD ["nginx"]

WORKDIR /home/strus
EXPOSE 80

