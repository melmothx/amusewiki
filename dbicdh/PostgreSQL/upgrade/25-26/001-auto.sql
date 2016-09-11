-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "bookbuilder_session" (
  "bookbuilder_session_id" serial NOT NULL,
  "token" character varying(16) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "bb_data" text NOT NULL,
  "last_updated" timestamp NOT NULL,
  PRIMARY KEY ("bookbuilder_session_id")
);
CREATE INDEX "bookbuilder_session_idx_site_id" on "bookbuilder_session" ("site_id");

;
ALTER TABLE "bookbuilder_session" ADD CONSTRAINT "bookbuilder_session_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

