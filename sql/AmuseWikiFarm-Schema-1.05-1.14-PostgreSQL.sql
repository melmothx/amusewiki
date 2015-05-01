-- Convert schema 'sql/AmuseWikiFarm-Schema-1.05-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-1.14-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "site_link" (
  "url" character varying(255) NOT NULL,
  "label" character varying(255) NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "site_id" character varying(16) NOT NULL
);
CREATE INDEX "site_link_idx_site_id" on "site_link" ("site_id");

ALTER TABLE "site_link" ADD CONSTRAINT "site_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;

ALTER TABLE site_options ALTER COLUMN option_value TYPE text;


COMMIT;

