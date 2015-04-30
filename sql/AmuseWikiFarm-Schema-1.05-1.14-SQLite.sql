-- Convert schema 'sql/AmuseWikiFarm-Schema-1.05-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-1.14-SQLite.sql':;

BEGIN;

CREATE TABLE "site_link" (
  "url" varchar(255) NOT NULL,
  "label" varchar(255) NOT NULL,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "site_link_idx_site_id" ON "site_link" ("site_id");

CREATE TEMPORARY TABLE "site_options_temp_alter" (
  "site_id" varchar(16) NOT NULL,
  "option_name" varchar(64) NOT NULL,
  "option_value" text,
  PRIMARY KEY ("site_id", "option_name"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "site_options_temp_alter"( "site_id", "option_name", "option_value") SELECT "site_id", "option_name", "option_value" FROM "site_options";

DROP TABLE "site_options";

CREATE TABLE "site_options" (
  "site_id" varchar(16) NOT NULL,
  "option_name" varchar(64) NOT NULL,
  "option_value" text,
  PRIMARY KEY ("site_id", "option_name"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "site_options_idx_site_id03" ON "site_options" ("site_id");

INSERT INTO "site_options" SELECT "site_id", "option_name", "option_value" FROM "site_options_temp_alter";

DROP TABLE "site_options_temp_alter";


COMMIT;

