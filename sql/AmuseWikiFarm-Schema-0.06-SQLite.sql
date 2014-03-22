-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sat Mar 22 11:20:28 2014
-- 

BEGIN TRANSACTION;

--
-- Table: site
--
DROP TABLE site;

CREATE TABLE site (
  id varchar(8) NOT NULL,
  locale varchar(3) NOT NULL DEFAULT 'en',
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(32),
  mail varchar(128),
  canonical varchar(255) NOT NULL DEFAULT '',
  bb_page_limit integer NOT NULL DEFAULT 1000,
  tex integer NOT NULL DEFAULT 1,
  pdf integer NOT NULL DEFAULT 1,
  a4_pdf integer NOT NULL DEFAULT 1,
  lt_pdf integer NOT NULL DEFAULT 1,
  html integer NOT NULL DEFAULT 1,
  bare_html integer NOT NULL DEFAULT 1,
  epub integer NOT NULL DEFAULT 1,
  zip integer NOT NULL DEFAULT 1,
  ttdir varchar(1024) NOT NULL DEFAULT '',
  papersize varchar(64) NOT NULL DEFAULT '',
  division integer NOT NULL DEFAULT 12,
  bcor varchar(16) NOT NULL DEFAULT '0mm',
  fontsize integer NOT NULL DEFAULT 10,
  mainfont varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  twoside integer NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

--
-- Table: attachment
--
DROP TABLE attachment;

CREATE TABLE attachment (
  id INTEGER PRIMARY KEY NOT NULL,
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX attachment_idx_site_id ON attachment (site_id);

CREATE UNIQUE INDEX uri_site_id_unique ON attachment (uri, site_id);

--
-- Table: category
--
DROP TABLE category;

CREATE TABLE category (
  id INTEGER PRIMARY KEY NOT NULL,
  name text,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  sorting_pos integer NOT NULL DEFAULT 0,
  text_count integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX category_idx_site_id ON category (site_id);

CREATE UNIQUE INDEX uri_site_id_type_unique ON category (uri, site_id, type);

--
-- Table: job
--
DROP TABLE job;

CREATE TABLE job (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(8),
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

CREATE INDEX job_idx_site_id ON job (site_id);

--
-- Table: title
--
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
  attach varchar(255),
  pubdate datetime NOT NULL,
  status varchar(16) NOT NULL DEFAULT 'unpublished',
  f_path text NOT NULL,
  f_name varchar(255) NOT NULL,
  f_archive_rel_path varchar(4) NOT NULL,
  f_timestamp datetime NOT NULL,
  f_full_path_name text NOT NULL,
  f_suffix varchar(16) NOT NULL,
  uri varchar(255) NOT NULL,
  deleted text NOT NULL DEFAULT '',
  sorting_pos integer NOT NULL DEFAULT 0,
  site_id varchar(8) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_idx_site_id ON title (site_id);

CREATE UNIQUE INDEX uri_site_id_unique02 ON title (uri, site_id);

--
-- Table: vhost
--
DROP TABLE vhost;

CREATE TABLE vhost (
  name varchar(255) NOT NULL,
  site_id varchar(8),
  PRIMARY KEY (name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX vhost_idx_site_id ON vhost (site_id);

--
-- Table: title_category
--
DROP TABLE title_category;

CREATE TABLE title_category (
  title_id integer NOT NULL,
  category_id integer NOT NULL,
  PRIMARY KEY (title_id, category_id),
  FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX title_category_idx_category_id ON title_category (category_id);

CREATE INDEX title_category_idx_title_id ON title_category (title_id);

COMMIT;
