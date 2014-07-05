-- Convert schema 'sql/AmuseWikiFarm-Schema-0.15-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.20-SQLite.sql':;

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
  sitegroup varchar(255),
  sitegroup_label varchar(255),
  catalog_label varchar(255),
  specials_label varchar(255),
  multilanguage integer(1) NOT NULL DEFAULT 0,
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
  sitegroup varchar(255),
  sitegroup_label varchar(255),
  catalog_label varchar(255),
  specials_label varchar(255),
  multilanguage integer(1) NOT NULL DEFAULT 0,
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

CREATE TEMPORARY TABLE user_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer(1) NOT NULL DEFAULT 1
);

INSERT INTO user_temp_alter( id, username, password, email, active) SELECT id, username, password, email, active FROM user;

DROP TABLE user;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer(1) NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX username_unique03 ON user (username);

INSERT INTO user SELECT id, username, password, email, active FROM user_temp_alter;

DROP TABLE user_temp_alter;


COMMIT;

