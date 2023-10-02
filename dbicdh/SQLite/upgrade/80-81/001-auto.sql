-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/80/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "annotation" (
  "annotation_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "annotation_name" varchar(255) NOT NULL,
  "annotation_type" varchar(32) NOT NULL,
  "label" varchar(255) NOT NULL DEFAULT '',
  "priority" integer NOT NULL DEFAULT 0,
  "active" integer(1) NOT NULL DEFAULT 1,
  "private" integer(1) NOT NULL DEFAULT 0,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "annotation_idx_site_id" ON "annotation" ("site_id");

;
CREATE UNIQUE INDEX "site_id_annotation_name_unique" ON "annotation" ("site_id", "annotation_name");

;
CREATE TABLE "title_annotation" (
  "annotation_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "title_id"),
  FOREIGN KEY ("annotation_id") REFERENCES "annotation"("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "title_annotation_idx_annotation_id" ON "title_annotation" ("annotation_id");

;
CREATE INDEX "title_annotation_idx_title_id" ON "title_annotation" ("title_id");

;
ALTER TABLE oai_pmh_record ADD COLUMN metadata_format_description varchar(255);

;
ALTER TABLE title ADD COLUMN datefirst text;

;

COMMIT;

