-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/64/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE title_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  title text,
  subtitle text,
  lang varchar(3) NOT NULL DEFAULT 'en',
  date text,
  notes text,
  source text,
  list_title text,
  author text,
  uid varchar(255) NOT NULL DEFAULT '',
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  parent varchar(255),
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text,
  slides integer(1) NOT NULL DEFAULT 0,
  text_structure text,
  cover varchar(255) NOT NULL DEFAULT '',
  teaser text,
  sorting_pos integer NOT NULL DEFAULT 0,
  sku varchar(64) NOT NULL DEFAULT '',
  text_qualification varchar(32),
  text_size integer NOT NULL DEFAULT 0,
  attachment_index integer NOT NULL DEFAULT 0,
  blob_container integer(1) NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO title_temp_alter( id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, parent, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, slides, text_structure, cover, teaser, sorting_pos, sku, text_qualification, text_size, attachment_index, blob_container, site_id) SELECT id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, parent, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, slides, text_structure, cover, teaser, sorting_pos, sku, text_qualification, text_size, attachment_index, blob_container, site_id FROM title;

;
DROP TABLE title;

;
CREATE TABLE title (
  id INTEGER PRIMARY KEY NOT NULL,
  title text,
  subtitle text,
  lang varchar(3) NOT NULL DEFAULT 'en',
  date text,
  notes text,
  source text,
  list_title text,
  author text,
  uid varchar(255) NOT NULL DEFAULT '',
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  parent varchar(255),
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text,
  slides integer(1) NOT NULL DEFAULT 0,
  text_structure text,
  cover varchar(255) NOT NULL DEFAULT '',
  teaser text,
  sorting_pos integer NOT NULL DEFAULT 0,
  sku varchar(64) NOT NULL DEFAULT '',
  text_qualification varchar(32),
  text_size integer NOT NULL DEFAULT 0,
  attachment_index integer NOT NULL DEFAULT 0,
  blob_container integer(1) NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX title_idx_site_id02 ON title (site_id);

;
CREATE UNIQUE INDEX uri_f_class_site_id_unique02 ON title (uri, f_class, site_id);

;
INSERT INTO title SELECT id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, parent, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, slides, text_structure, cover, teaser, sorting_pos, sku, text_qualification, text_size, attachment_index, blob_container, site_id FROM title_temp_alter;

;
DROP TABLE title_temp_alter;

;

COMMIT;

