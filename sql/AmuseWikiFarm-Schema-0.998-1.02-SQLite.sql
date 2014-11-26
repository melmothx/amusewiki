-- Convert schema 'sql/AmuseWikiFarm-Schema-0.998-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-1.02-SQLite.sql':;

BEGIN;

CREATE TABLE "site_options" (
  "site_id" varchar(16) NOT NULL,
  "option_name" varchar(64) NOT NULL,
  "option_value" varchar(255),
  PRIMARY KEY ("site_id", "option_name"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "site_options_idx_site_id" ON "site_options" ("site_id");


COMMIT;

