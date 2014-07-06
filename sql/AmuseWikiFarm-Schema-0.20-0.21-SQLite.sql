-- Convert schema 'sql/AmuseWikiFarm-Schema-0.20-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.21-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE title_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  title text NOT NULL DEFAULT '',
  subtitle text NOT NULL DEFAULT '',
  lang varchar(3) NOT NULL DEFAULT 'en',
  date text NOT NULL DEFAULT '',
  notes text NOT NULL DEFAULT '',
  source text NOT NULL DEFAULT '',
  list_title text NOT NULL DEFAULT '',
  author text NOT NULL DEFAULT '',
  uid varchar(255),
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO title_temp_alter( id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, sorting_pos, site_id) SELECT id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, sorting_pos, site_id FROM title;

DROP TABLE title;

CREATE TABLE title (
  id INTEGER PRIMARY KEY NOT NULL,
  title text NOT NULL DEFAULT '',
  subtitle text NOT NULL DEFAULT '',
  lang varchar(3) NOT NULL DEFAULT 'en',
  date text NOT NULL DEFAULT '',
  notes text NOT NULL DEFAULT '',
  source text NOT NULL DEFAULT '',
  list_title text NOT NULL DEFAULT '',
  author text NOT NULL DEFAULT '',
  uid varchar(255),
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_idx_site_id03 ON title (site_id);

CREATE UNIQUE INDEX uri_f_class_site_id_unique03 ON title (uri, f_class, site_id);

INSERT INTO title SELECT id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, sorting_pos, site_id FROM title_temp_alter;

DROP TABLE title_temp_alter;


COMMIT;

