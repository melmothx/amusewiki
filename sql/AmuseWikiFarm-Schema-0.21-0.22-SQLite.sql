-- Convert schema 'sql/AmuseWikiFarm-Schema-0.21-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.22-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE site_temp_alter (
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
  canonical varchar(255) NOT NULL DEFAULT '',
  sitegroup varchar(255) NOT NULL DEFAULT '',
  sitegroup_label varchar(255),
  catalog_label varchar(255),
  specials_label varchar(255),
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
  twoside integer(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

INSERT INTO site_temp_alter( id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, sitegroup_label, catalog_label, specials_label, multilanguage, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside) SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, sitegroup_label, catalog_label, specials_label, multilanguage, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside FROM site;

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
  canonical varchar(255) NOT NULL DEFAULT '',
  sitegroup varchar(255) NOT NULL DEFAULT '',
  sitegroup_label varchar(255),
  catalog_label varchar(255),
  specials_label varchar(255),
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
  twoside integer(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

INSERT INTO site SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, sitegroup_label, catalog_label, specials_label, multilanguage, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside FROM site_temp_alter;

DROP TABLE site_temp_alter;

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
  uid varchar(255) NOT NULL DEFAULT '',
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

