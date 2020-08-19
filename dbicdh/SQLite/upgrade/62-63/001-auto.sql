-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "included_file" (
  "included_file_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer NOT NULL,
  "file_path" text NOT NULL,
  "file_timestamp" datetime,
  "file_epoch" integer,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "included_file_idx_site_id" ON "included_file" ("site_id");

;
CREATE INDEX "included_file_idx_title_id" ON "included_file" ("title_id");

;

COMMIT;

