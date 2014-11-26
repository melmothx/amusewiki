-- Convert schema 'sql/AmuseWikiFarm-Schema-0.998-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-1.02-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "site_options" (
  "site_id" character varying(16) NOT NULL,
  "option_name" character varying(64) NOT NULL,
  "option_value" character varying(255),
  PRIMARY KEY ("site_id", "option_name")
);
CREATE INDEX "site_options_idx_site_id" on "site_options" ("site_id");

ALTER TABLE "site_options" ADD CONSTRAINT "site_options_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;


COMMIT;

