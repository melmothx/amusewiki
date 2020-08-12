-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "included_file" (
  "included_file_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer NOT NULL,
  "file_path" text NOT NULL,
  "file_timestamp" timestamp,
  "file_epoch" integer,
  PRIMARY KEY ("included_file_id")
);
CREATE INDEX "included_file_idx_site_id" on "included_file" ("site_id");
CREATE INDEX "included_file_idx_title_id" on "included_file" ("title_id");

;
ALTER TABLE "included_file" ADD CONSTRAINT "included_file_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "included_file" ADD CONSTRAINT "included_file_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

