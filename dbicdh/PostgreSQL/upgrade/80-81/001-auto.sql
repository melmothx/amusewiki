-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/80/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "annotation" (
  "annotation_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "annotation_name" character varying(255) NOT NULL,
  "annotation_type" character varying(32) NOT NULL,
  "label" character varying(255) DEFAULT '' NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "active" smallint DEFAULT 1 NOT NULL,
  "private" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("annotation_id"),
  CONSTRAINT "site_id_annotation_name_unique" UNIQUE ("site_id", "annotation_name")
);
CREATE INDEX "annotation_idx_site_id" on "annotation" ("site_id");

;
CREATE TABLE "title_annotation" (
  "annotation_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "title_id")
);
CREATE INDEX "title_annotation_idx_annotation_id" on "title_annotation" ("annotation_id");
CREATE INDEX "title_annotation_idx_title_id" on "title_annotation" ("title_id");

;
ALTER TABLE "annotation" ADD CONSTRAINT "annotation_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_annotation" ADD CONSTRAINT "title_annotation_fk_annotation_id" FOREIGN KEY ("annotation_id")
  REFERENCES "annotation" ("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_annotation" ADD CONSTRAINT "title_annotation_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD COLUMN "metadata_format_description" character varying(255);

;
ALTER TABLE "title" ADD COLUMN "datefirst" text;

;

COMMIT;

