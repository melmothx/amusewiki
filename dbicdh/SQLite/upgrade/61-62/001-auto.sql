-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/61/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "include_path" (
  "include_path_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "directory" text,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "include_path_idx_site_id" ON "include_path" ("site_id");

;

COMMIT;

