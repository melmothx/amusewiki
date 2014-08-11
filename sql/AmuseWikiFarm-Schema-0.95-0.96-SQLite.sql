-- Convert schema 'sql/AmuseWikiFarm-Schema-0.95-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.96-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE attachment_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO attachment_temp_alter( id, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, site_id) SELECT id, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, site_id FROM attachment;

DROP TABLE attachment;

CREATE TABLE attachment (
  id INTEGER PRIMARY KEY NOT NULL,
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX attachment_idx_site_id03 ON attachment (site_id);

CREATE UNIQUE INDEX uri_site_id_unique03 ON attachment (uri, site_id);

INSERT INTO attachment SELECT id, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, site_id FROM attachment_temp_alter;

DROP TABLE attachment_temp_alter;

CREATE TEMPORARY TABLE category_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name text,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  sorting_pos integer NOT NULL DEFAULT 0,
  text_count integer NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO category_temp_alter( id, name, uri, type, sorting_pos, text_count, site_id) SELECT id, name, uri, type, sorting_pos, text_count, site_id FROM category;

DROP TABLE category;

CREATE TABLE category (
  id INTEGER PRIMARY KEY NOT NULL,
  name text,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  sorting_pos integer NOT NULL DEFAULT 0,
  text_count integer NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX category_idx_site_id03 ON category (site_id);

CREATE UNIQUE INDEX uri_site_id_type_unique03 ON category (uri, site_id, type);

INSERT INTO category SELECT id, name, uri, type, sorting_pos, text_count, site_id FROM category_temp_alter;

DROP TABLE category_temp_alter;

CREATE TEMPORARY TABLE job_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  task varchar(32),
  payload text,
  status varchar(32),
  created datetime NOT NULL,
  completed datetime,
  priority integer,
  produced varchar(255),
  errors text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO job_temp_alter( id, site_id, task, payload, status, created, completed, priority, produced, errors) SELECT id, site_id, task, payload, status, created, completed, priority, produced, errors FROM job;

DROP TABLE job;

CREATE TABLE job (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  task varchar(32),
  payload text,
  status varchar(32),
  created datetime NOT NULL,
  completed datetime,
  priority integer,
  produced varchar(255),
  errors text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX job_idx_site_id03 ON job (site_id);

INSERT INTO job SELECT id, site_id, task, payload, status, created, completed, priority, produced, errors FROM job_temp_alter;

DROP TABLE job_temp_alter;

CREATE TEMPORARY TABLE redirection_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  redirect varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO redirection_temp_alter( id, uri, type, redirect, site_id) SELECT id, uri, type, redirect, site_id FROM redirection;

DROP TABLE redirection;

CREATE TABLE redirection (
  id INTEGER PRIMARY KEY NOT NULL,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  redirect varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX redirection_idx_site_id03 ON redirection (site_id);

CREATE UNIQUE INDEX uri_type_site_id_unique03 ON redirection (uri, type, site_id);

INSERT INTO redirection SELECT id, uri, type, redirect, site_id FROM redirection_temp_alter;

DROP TABLE redirection_temp_alter;

CREATE TEMPORARY TABLE revision_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
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
  site_id varchar(16) NOT NULL,
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
  uid varchar(255) NOT NULL DEFAULT '',
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
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
  uid varchar(255) NOT NULL DEFAULT '',
  attach text,
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(32) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_timestamp_epoch integer NOT NULL DEFAULT 0,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  f_class varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_idx_site_id03 ON title (site_id);

CREATE UNIQUE INDEX uri_f_class_site_id_unique03 ON title (uri, f_class, site_id);

INSERT INTO title SELECT id, title, subtitle, lang, date, notes, source, list_title, author, uid, attach, pubdate, status, f_path, f_name, f_archive_rel_path, f_timestamp, f_timestamp_epoch, f_full_path_name, f_suffix, f_class, uri, deleted, sorting_pos, site_id FROM title_temp_alter;

DROP TABLE title_temp_alter;

CREATE TEMPORARY TABLE user_site_temp_alter (
  user_id integer NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (user_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO user_site_temp_alter( user_id, site_id) SELECT user_id, site_id FROM user_site;

DROP TABLE user_site;

CREATE TABLE user_site (
  user_id integer NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (user_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_site_idx_site_id03 ON user_site (site_id);

CREATE INDEX user_site_idx_user_id03 ON user_site (user_id);

INSERT INTO user_site SELECT user_id, site_id FROM user_site_temp_alter;

DROP TABLE user_site_temp_alter;

CREATE TEMPORARY TABLE vhost_temp_alter (
  name varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO vhost_temp_alter( name, site_id) SELECT name, site_id FROM vhost;

DROP TABLE vhost;

CREATE TABLE vhost (
  name varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX vhost_idx_site_id03 ON vhost (site_id);

INSERT INTO vhost SELECT name, site_id FROM vhost_temp_alter;

DROP TABLE vhost_temp_alter;


COMMIT;

