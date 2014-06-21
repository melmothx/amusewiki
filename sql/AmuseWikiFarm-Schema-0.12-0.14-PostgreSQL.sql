-- Convert schema 'sql/AmuseWikiFarm-Schema-0.12-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-0.14-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "redirection" (
  "id" serial NOT NULL,
  "uri" character varying(255) NOT NULL,
  "type" character varying(16) NOT NULL,
  "redirect" character varying(255) NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_type_site_id_unique" UNIQUE ("uri", "type", "site_id")
);
CREATE INDEX "redirection_idx_site_id" on "redirection" ("site_id");

ALTER TABLE "redirection" ADD CONSTRAINT "redirection_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;


COMMIT;

