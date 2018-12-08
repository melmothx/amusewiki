-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/20/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE site_temp_alter (
  id varchar(16) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'private',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question varchar(255) NOT NULL DEFAULT '12 + 4 =',
  magic_answer varchar(255) NOT NULL DEFAULT '16',
  fixed_category_list varchar(255),
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(255) NOT NULL DEFAULT '',
  mail_notify varchar(255),
  mail_from varchar(255),
  canonical varchar(255) NOT NULL,
  secure_site integer(1) NOT NULL DEFAULT 1,
  secure_site_only integer(1) NOT NULL DEFAULT 0,
  sitegroup varchar(255) NOT NULL DEFAULT '',
  cgit_integration integer(1) NOT NULL DEFAULT 1,
  ssl_key varchar(255) NOT NULL DEFAULT '',
  ssl_cert varchar(255) NOT NULL DEFAULT '',
  ssl_ca_cert varchar(255) NOT NULL DEFAULT '',
  ssl_chained_cert varchar(255) NOT NULL DEFAULT '',
  acme_certificate integer(1) NOT NULL DEFAULT 0,
  multilanguage varchar(255) NOT NULL DEFAULT '',
  active integer(1) NOT NULL DEFAULT 1,
  blog_style integer(1) NOT NULL DEFAULT 0,
  bb_page_limit integer NOT NULL DEFAULT 1000,
  tex integer(1) NOT NULL DEFAULT 1,
  pdf integer(1) NOT NULL DEFAULT 1,
  a4_pdf integer(1) NOT NULL DEFAULT 0,
  lt_pdf integer(1) NOT NULL DEFAULT 0,
  sl_pdf integer(1) NOT NULL DEFAULT 0,
  html integer(1) NOT NULL DEFAULT 1,
  bare_html integer(1) NOT NULL DEFAULT 1,
  epub integer(1) NOT NULL DEFAULT 1,
  zip integer(1) NOT NULL DEFAULT 1,
  ttdir varchar(255) NOT NULL DEFAULT '',
  papersize varchar(64) NOT NULL DEFAULT '',
  division integer NOT NULL DEFAULT 12,
  bcor varchar(16) NOT NULL DEFAULT '0mm',
  fontsize integer NOT NULL DEFAULT 10,
  mainfont varchar(255) NOT NULL DEFAULT 'CMU Serif',
  sansfont varchar(255) NOT NULL DEFAULT 'CMU Sans Serif',
  monofont varchar(255) NOT NULL DEFAULT 'CMU Typewriter Text',
  beamertheme varchar(255) NOT NULL DEFAULT 'default',
  beamercolortheme varchar(255) NOT NULL DEFAULT 'dove',
  nocoverpage integer(1) NOT NULL DEFAULT 0,
  logo_with_sitename integer(1) NOT NULL DEFAULT 0,
  opening varchar(16) NOT NULL DEFAULT 'any',
  twoside integer(1) NOT NULL DEFAULT 0,
  last_updated datetime,
  PRIMARY KEY (id)
);

;
INSERT INTO site_temp_alter( id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, secure_site, secure_site_only, sitegroup, cgit_integration, ssl_key, ssl_cert, ssl_ca_cert, ssl_chained_cert, acme_certificate, multilanguage, active, blog_style, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, sl_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, sansfont, monofont, beamertheme, beamercolortheme, nocoverpage, logo_with_sitename, opening, twoside, last_updated) SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, secure_site, secure_site_only, sitegroup, cgit_integration, ssl_key, ssl_cert, ssl_ca_cert, ssl_chained_cert, acme_certificate, multilanguage, active, blog_style, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, sl_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, sansfont, monofont, beamertheme, beamercolortheme, nocoverpage, logo_with_sitename, opening, twoside, last_updated FROM site;

;
DROP TABLE site;

;
CREATE TABLE site (
  id varchar(16) NOT NULL,
  mode varchar(16) NOT NULL DEFAULT 'private',
  locale varchar(3) NOT NULL DEFAULT 'en',
  magic_question varchar(255) NOT NULL DEFAULT '12 + 4 =',
  magic_answer varchar(255) NOT NULL DEFAULT '16',
  fixed_category_list varchar(255),
  sitename varchar(255) NOT NULL DEFAULT '',
  siteslogan varchar(255) NOT NULL DEFAULT '',
  theme varchar(32) NOT NULL DEFAULT '',
  logo varchar(255) NOT NULL DEFAULT '',
  mail_notify varchar(255),
  mail_from varchar(255),
  canonical varchar(255) NOT NULL,
  secure_site integer(1) NOT NULL DEFAULT 1,
  secure_site_only integer(1) NOT NULL DEFAULT 0,
  sitegroup varchar(255) NOT NULL DEFAULT '',
  cgit_integration integer(1) NOT NULL DEFAULT 1,
  ssl_key varchar(255) NOT NULL DEFAULT '',
  ssl_cert varchar(255) NOT NULL DEFAULT '',
  ssl_ca_cert varchar(255) NOT NULL DEFAULT '',
  ssl_chained_cert varchar(255) NOT NULL DEFAULT '',
  acme_certificate integer(1) NOT NULL DEFAULT 0,
  multilanguage varchar(255) NOT NULL DEFAULT '',
  active integer(1) NOT NULL DEFAULT 1,
  blog_style integer(1) NOT NULL DEFAULT 0,
  bb_page_limit integer NOT NULL DEFAULT 1000,
  tex integer(1) NOT NULL DEFAULT 1,
  pdf integer(1) NOT NULL DEFAULT 1,
  a4_pdf integer(1) NOT NULL DEFAULT 0,
  lt_pdf integer(1) NOT NULL DEFAULT 0,
  sl_pdf integer(1) NOT NULL DEFAULT 0,
  html integer(1) NOT NULL DEFAULT 1,
  bare_html integer(1) NOT NULL DEFAULT 1,
  epub integer(1) NOT NULL DEFAULT 1,
  zip integer(1) NOT NULL DEFAULT 1,
  ttdir varchar(255) NOT NULL DEFAULT '',
  papersize varchar(64) NOT NULL DEFAULT '',
  division integer NOT NULL DEFAULT 12,
  bcor varchar(16) NOT NULL DEFAULT '0mm',
  fontsize integer NOT NULL DEFAULT 10,
  mainfont varchar(255) NOT NULL DEFAULT 'CMU Serif',
  sansfont varchar(255) NOT NULL DEFAULT 'CMU Sans Serif',
  monofont varchar(255) NOT NULL DEFAULT 'CMU Typewriter Text',
  beamertheme varchar(255) NOT NULL DEFAULT 'default',
  beamercolortheme varchar(255) NOT NULL DEFAULT 'dove',
  nocoverpage integer(1) NOT NULL DEFAULT 0,
  logo_with_sitename integer(1) NOT NULL DEFAULT 0,
  opening varchar(16) NOT NULL DEFAULT 'any',
  twoside integer(1) NOT NULL DEFAULT 0,
  last_updated datetime,
  PRIMARY KEY (id)
);

;
CREATE UNIQUE INDEX canonical_unique02 ON site (canonical);

;
INSERT INTO site SELECT id, mode, locale, magic_question, magic_answer, fixed_category_list, sitename, siteslogan, theme, logo, mail_notify, mail_from, canonical, secure_site, secure_site_only, sitegroup, cgit_integration, ssl_key, ssl_cert, ssl_ca_cert, ssl_chained_cert, acme_certificate, multilanguage, active, blog_style, bb_page_limit, tex, pdf, a4_pdf, lt_pdf, sl_pdf, html, bare_html, epub, zip, ttdir, papersize, division, bcor, fontsize, mainfont, sansfont, monofont, beamertheme, beamercolortheme, nocoverpage, logo_with_sitename, opening, twoside, last_updated FROM site_temp_alter;

;
DROP TABLE site_temp_alter;

;

COMMIT;

