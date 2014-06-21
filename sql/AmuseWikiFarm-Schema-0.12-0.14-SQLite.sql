-- Convert schema 'sql/AmuseWikiFarm-Schema-0.12-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.14-SQLite.sql':;

BEGIN;

CREATE TABLE redirection (
  id INTEGER PRIMARY KEY NOT NULL,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  redirect varchar(255) NOT NULL,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX redirection_idx_site_id ON redirection (site_id);

CREATE UNIQUE INDEX uri_type_site_id_unique ON redirection (uri, type, site_id);


COMMIT;

