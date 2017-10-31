-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "global_site_files" (
  "site_id" character varying(16) NOT NULL,
  "attachment_id" integer,
  "file_name" character varying(255) NOT NULL,
  "file_type" character varying(255) NOT NULL,
  "file_path" text NOT NULL,
  "image_width" integer,
  "image_height" integer,
  PRIMARY KEY ("site_id", "file_name")
);
CREATE INDEX "global_site_files_idx_attachment_id" on "global_site_files" ("attachment_id");
CREATE INDEX "global_site_files_idx_site_id" on "global_site_files" ("site_id");

;
ALTER TABLE "global_site_files" ADD CONSTRAINT "global_site_files_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "global_site_files" ADD CONSTRAINT "global_site_files_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

