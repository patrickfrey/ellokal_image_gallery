# Docker image for the El Lokal (Zürich) image gallery:
# -----------------------------------------------------

FROM patrickfrey/strus-ub1404-pqnx
MAINTAINER patrickpfrey@yahoo.com

COPY ./entrypoint.sh /srv/entrypoint.sh

# Web server:
# -----------
USER root
WORKDIR /etc/nginx
ENTRYPOINT ["/srv/entrypoint.sh"]
CMD ["nginx"]

WORKDIR /home/strus
EXPOSE 80

