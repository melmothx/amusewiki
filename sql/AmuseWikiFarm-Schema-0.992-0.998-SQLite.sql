-- Convert schema 'sql/AmuseWikiFarm-Schema-0.992-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.998-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE "site_temp_alter" (
  "id" varchar(16) NOT NULL,
  "mode" varchar(16) NOT NULL DEFAULT 'blog',
  "locale" varchar(3) NOT NULL DEFAULT 'en',
  "magic_question" varchar(255) NOT NULL DEFAULT '',
  "magic_answer" varchar(255) NOT NULL DEFAULT '',
  "fixed_category_list" varchar(255),
  "sitename" varchar(255) NOT NULL DEFAULT '',
  "siteslogan" varchar(255) NOT NULL DEFAULT '',
  "theme" varchar(32) NOT NULL DEFAULT '',
  "logo" varchar(255),
  "mail_notify" varchar(255),
  "mail_from" varchar(255),
  "canonical" varchar(255) NOT NULL,
  "secure_site" integer(1) NOT NULL DEFAULT 0,
  "sitegroup" varchar(255) NOT NULL DEFAULT '',
  "sitegroup_label" varchar(255),
  "catalog_label" varchar(255),
  "specials_label" varchar(255),
  "cgit_integration" integer(1) NOT NULL DEFAULT 0,
  "multilanguage" varchar(255) NOT NULL DEFAULT '',
  "bb_page_limit" integer NOT NULL DEFAULT 1000,
  "tex" integer(1) NOT NULL DEFAULT 1,
  "pdf" integer(1) NOT NULL DEFAULT 1,
  "a4_pdf" integer(1) NOT NULL DEFAULT 1,
  "lt_pdf" integer(1) NOT NULL DEFAULT 1,
  "html" integer(1) NOT NULL DEFAULT 1,
  "bare_html" integer(1) NOT NULL DEFAULT 1,
  "epub" integer(1) NOT NULL DEFAULT 1,
  "zip" integer(1) NOT NULL DEFAULT 1,
  "ttdir" varchar(255) NOT NULL DEFAULT '',
  "papersize" varchar(64) NOT NULL DEFAULT '',
  "division" integer NOT NULL DEFAULT 12,
  "bcor" varchar(16) NOT NULL DEFAULT '0mm',
  "fontsize" integer NOT NULL DEFAULT 10,
  "mainfont" varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  "nocoverpage" integer(1) NOT NULL DEFAULT 0,
  "logo_with_sitename" integer(1) NOT NULL DEFAULT 0,
  "twoside" integer(1) NOT NULL DEFAULT 0,
  PRIMARY KEY ("id")
);

INSERT INTO "site_temp_alter"( "id", "mode", "locale", "magic_question", "magic_answer", "fixed_category_list", "sitename", "siteslogan", "theme", "logo", "mail_notify", "mail_from", "canonical", "secure_site", "sitegroup", "sitegroup_label", "catalog_label", "specials_label", "cgit_integration", "multilanguage", "bb_page_limit", "tex", "pdf", "a4_pdf", "lt_pdf", "html", "bare_html", "epub", "zip", "ttdir", "papersize", "division", "bcor", "fontsize", "mainfont", "nocoverpage", "logo_with_sitename", "twoside") SELECT "id", "mode", "locale", "magic_question", "magic_answer", "fixed_category_list", "sitename", "siteslogan", "theme", "logo", "mail_notify", "mail_from", "canonical", "secure_site", "sitegroup", "sitegroup_label", "catalog_label", "specials_label", "cgit_integration", "multilanguage", "bb_page_limit", "tex", "pdf", "a4_pdf", "lt_pdf", "html", "bare_html", "epub", "zip", "ttdir", "papersize", "division", "bcor", "fontsize", "mainfont", "nocoverpage", "logo_with_sitename", "twoside" FROM "site";

DROP TABLE "site";

CREATE TABLE "site" (
  "id" varchar(16) NOT NULL,
  "mode" varchar(16) NOT NULL DEFAULT 'blog',
  "locale" varchar(3) NOT NULL DEFAULT 'en',
  "magic_question" varchar(255) NOT NULL DEFAULT '',
  "magic_answer" varchar(255) NOT NULL DEFAULT '',
  "fixed_category_list" varchar(255),
  "sitename" varchar(255) NOT NULL DEFAULT '',
  "siteslogan" varchar(255) NOT NULL DEFAULT '',
  "theme" varchar(32) NOT NULL DEFAULT '',
  "logo" varchar(255),
  "mail_notify" varchar(255),
  "mail_from" varchar(255),
  "canonical" varchar(255) NOT NULL,
  "secure_site" integer(1) NOT NULL DEFAULT 0,
  "sitegroup" varchar(255) NOT NULL DEFAULT '',
  "sitegroup_label" varchar(255),
  "catalog_label" varchar(255),
  "specials_label" varchar(255),
  "cgit_integration" integer(1) NOT NULL DEFAULT 0,
  "multilanguage" varchar(255) NOT NULL DEFAULT '',
  "bb_page_limit" integer NOT NULL DEFAULT 1000,
  "tex" integer(1) NOT NULL DEFAULT 1,
  "pdf" integer(1) NOT NULL DEFAULT 1,
  "a4_pdf" integer(1) NOT NULL DEFAULT 1,
  "lt_pdf" integer(1) NOT NULL DEFAULT 1,
  "html" integer(1) NOT NULL DEFAULT 1,
  "bare_html" integer(1) NOT NULL DEFAULT 1,
  "epub" integer(1) NOT NULL DEFAULT 1,
  "zip" integer(1) NOT NULL DEFAULT 1,
  "ttdir" varchar(255) NOT NULL DEFAULT '',
  "papersize" varchar(64) NOT NULL DEFAULT '',
  "division" integer NOT NULL DEFAULT 12,
  "bcor" varchar(16) NOT NULL DEFAULT '0mm',
  "fontsize" integer NOT NULL DEFAULT 10,
  "mainfont" varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  "nocoverpage" integer(1) NOT NULL DEFAULT 0,
  "logo_with_sitename" integer(1) NOT NULL DEFAULT 0,
  "twoside" integer(1) NOT NULL DEFAULT 0,
  PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "canonical_unique03" ON "site" ("canonical");

INSERT INTO "site" SELECT "id", "mode", "locale", "magic_question", "magic_answer", "fixed_category_list", "sitename", "siteslogan", "theme", "logo", "mail_notify", "mail_from", "canonical", "secure_site", "sitegroup", "sitegroup_label", "catalog_label", "specials_label", "cgit_integration", "multilanguage", "bb_page_limit", "tex", "pdf", "a4_pdf", "lt_pdf", "html", "bare_html", "epub", "zip", "ttdir", "papersize", "division", "bcor", "fontsize", "mainfont", "nocoverpage", "logo_with_sitename", "twoside" FROM "site_temp_alter";

DROP TABLE "site_temp_alter";


COMMIT;

