-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Nov 26 12:09:14 2014
-- 

BEGIN TRANSACTION;

--
-- Table: site_options
--
DROP TABLE site_options;

CREATE TABLE site_options (
  site_id varchar(16) NOT NULL,
  option_name varchar(64) NOT NULL,
  option_value varchar(255),
  PRIMARY KEY (site_id, option_name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX site_options_idx_site_id ON site_options (site_id);

--
-- Table: roles
--
DROP TABLE roles;

CREATE TABLE roles (
  id INTEGER PRIMARY KEY NOT NULL,
  role varchar(128)
);

CREATE UNIQUE INDEX role_unique ON roles (role);

--
-- Table: site
--
DROP TABLE site;

CREATE TABLE site (
  id varchar(16) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'blog',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question varchar(255) NOT NULL DEFAULT '',
  magic_answer varchar(255) NOT NULL DEFAULT '',
  fixed_category_list varchar(255),
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(255),
  mail_notify varchar(255),
  mail_from varchar(255),
  canonical varchar(255) NOT NULL,
  secure_site integer(1) NOT NULL DEFAULT 0,
  sitegroup varchar(255) NOT NULL DEFAULT '',
  sitegroup_label varchar(255),
  catalog_label varchar(255),
  specials_label varchar(255),
  cgit_integration integer(1) NOT NULL DEFAULT 0,
  multilanguage varchar(255) NOT NULL DEFAULT '',
  bb_page_limit integer NOT NULL DEFAULT 1000,
  tex integer(1) NOT NULL DEFAULT 1,
  pdf integer(1) NOT NULL DEFAULT 1,
  a4_pdf integer(1) NOT NULL DEFAULT 1,
  lt_pdf integer(1) NOT NULL DEFAULT 1,
  html integer(1) NOT NULL DEFAULT 1,
  bare_html integer(1) NOT NULL DEFAULT 1,
  epub integer(1) NOT NULL DEFAULT 1,
  zip integer(1) NOT NULL DEFAULT 1,
  ttdir varchar(255) NOT NULL DEFAULT '',
  papersize varchar(64) NOT NULL DEFAULT '',
  division integer NOT NULL DEFAULT 12,
  bcor varchar(16) NOT NULL DEFAULT '0mm',
  fontsize integer NOT NULL DEFAULT 10,
  mainfont varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  nocoverpage integer(1) NOT NULL DEFAULT 0,
  logo_with_sitename integer(1) NOT NULL DEFAULT 0,
  twoside integer(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX canonical_unique ON site (canonical);

--
-- Table: users
--
DROP TABLE users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer(1) NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX username_unique ON users (username);

--
-- Table: attachment
--
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
  site_id varchar(16) NOT NULL,
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

CREATE INDEX job_idx_site_id ON job (site_id);

--
-- Table: redirection
--
DROP TABLE redirection;

CREATE TABLE redirection (
  id INTEGER PRIMARY KEY NOT NULL,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  redirect varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX redirection_idx_site_id ON redirection (site_id);

CREATE UNIQUE INDEX uri_type_site_id_unique ON redirection (uri, type, site_id);

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

CREATE INDEX title_idx_site_id ON title (site_id);

CREATE UNIQUE INDEX uri_f_class_site_id_unique ON title (uri, f_class, site_id);

--
-- Table: vhost
--
DROP TABLE vhost;

CREATE TABLE vhost (
  name varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (name),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX vhost_idx_site_id ON vhost (site_id);

--
-- Table: revision
--
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

CREATE INDEX revision_idx_site_id ON revision (site_id);

CREATE INDEX revision_idx_title_id ON revision (title_id);

--
-- Table: user_role
--
DROP TABLE user_role;

CREATE TABLE user_role (
  user_id integer NOT NULL,
  role_id integer NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_role_idx_role_id ON user_role (role_id);

CREATE INDEX user_role_idx_user_id ON user_role (user_id);

--
-- Table: user_site
--
DROP TABLE user_site;

CREATE TABLE user_site (
  user_id integer NOT NULL,
  site_id varchar(16) NOT NULL,
  PRIMARY KEY (user_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_site_idx_site_id ON user_site (site_id);

CREATE INDEX user_site_idx_user_id ON user_site (user_id);

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
