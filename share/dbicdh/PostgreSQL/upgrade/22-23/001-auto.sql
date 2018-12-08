-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "legacy_link" (
  "site_id" character varying(16) NOT NULL,
  "legacy_path" character varying(255) NOT NULL,
  "new_path" character varying(255) NOT NULL,
  PRIMARY KEY ("site_id", "legacy_path")
);
CREATE INDEX "legacy_link_idx_site_id" on "legacy_link" ("site_id");

;
ALTER TABLE "legacy_link" ADD CONSTRAINT "legacy_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

