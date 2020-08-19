-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/61/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "include_path" (
  "include_path_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "directory" text,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("include_path_id")
);
CREATE INDEX "include_path_idx_site_id" on "include_path" ("site_id");

;
ALTER TABLE "include_path" ADD CONSTRAINT "include_path_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

