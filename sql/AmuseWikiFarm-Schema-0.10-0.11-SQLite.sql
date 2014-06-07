-- Convert schema 'sql/AmuseWikiFarm-Schema-0.10-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.11-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE revision_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(8) NOT NULL,
  title_id integer NOT NULL,
  f_full_path_name text,
  message text,
  status varchar(16) NOT NULL DEFAULT 'editing',
  session_id varchar(255),
  updated datetime NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO revision_temp_alter( id, site_id, title_id, f_full_path_name, message, status, session_id, updated) SELECT id, site_id, title_id, f_full_path_name, message, status, session_id, updated FROM revision;

DROP TABLE revision;

CREATE TABLE revision (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(8) NOT NULL,
  title_id integer NOT NULL,
  f_full_path_name text,
  message text,
  status varchar(16) NOT NULL DEFAULT 'editing',
  session_id varchar(255),
  updated datetime NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX revision_idx_site_id03 ON revision (site_id);

CREATE INDEX revision_idx_title_id03 ON revision (title_id);

INSERT INTO revision SELECT id, site_id, title_id, f_full_path_name, message, status, session_id, updated FROM revision_temp_alter;

DROP TABLE revision_temp_alter;


COMMIT;

