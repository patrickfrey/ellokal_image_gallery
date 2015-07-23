
CREATE USER elroot WITH
      LOGIN
      CONNECTION LIMIT 1
      PASSWORD 'v4uwf314d5#rt';

CREATE USER ellokal WITH
      NOLOGIN
      CONNECTION LIMIT 30
      PASSWORD '1w5b5ufh';

CREATE DATABASE ellokaldb
      TEMPLATE template0
      ENCODING 'UTF8'
          CONNECTION LIMIT 30;

REVOKE CONNECT ON DATABASE ellokaldb FROM PUBLIC;
GRANT ALL PRIVILEGES ON DATABASE ellokaldb to elroot;
GRANT CONNECT ON DATABASE ellokaldb TO elroot;

GRANT CONNECT ON DATABASE ellokaldb TO ellokal;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ellokal;


