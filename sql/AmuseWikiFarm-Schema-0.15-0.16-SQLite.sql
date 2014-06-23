-- Convert schema 'sql/AmuseWikiFarm-Schema-0.15-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.16-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE site_temp_alter (
  id varchar(16) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'blog',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question text NOT NULL DEFAULT '',
  magic_answer text NOT NULL DEFAULT '',
  fixed_category_list text,
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(32),
  mail_notify varchar(255),
  mail_from varchar(255),
  canonical varchar(255) NOT NULL DEFAULT '',
  sitegroup varchar(32),
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

INSERT INTO site_temp_alter( id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside) SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside FROM site;

DROP TABLE site;

CREATE TABLE site (
  id varchar(16) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'blog',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question text NOT NULL DEFAULT '',
  magic_answer text NOT NULL DEFAULT '',
  fixed_category_list text,
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(32),
  mail_notify varchar(255),
  mail_from varchar(255),
  canonical varchar(255) NOT NULL DEFAULT '',
  sitegroup varchar(32),
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

INSERT INTO site SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, sitegroup, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, twoside FROM site_temp_alter;

DROP TABLE site_temp_alter;


COMMIT;

