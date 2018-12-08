-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/45/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/46/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "amw_session" (
  "session_id" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "expires" integer,
  "session_data" bytea,
  "flash_data" bytea,
  "generic_data" bytea,
  PRIMARY KEY ("session_id", "site_id")
);
CREATE INDEX "amw_session_idx_site_id" on "amw_session" ("site_id");

;
ALTER TABLE "amw_session" ADD CONSTRAINT "amw_session_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

