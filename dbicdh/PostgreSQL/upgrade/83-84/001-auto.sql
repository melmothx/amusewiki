-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation_annotation" (
  "annotation_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "aggregation_id")
);
CREATE INDEX "aggregation_annotation_idx_aggregation_id" on "aggregation_annotation" ("aggregation_id");
CREATE INDEX "aggregation_annotation_idx_annotation_id" on "aggregation_annotation" ("annotation_id");

;
ALTER TABLE "aggregation_annotation" ADD CONSTRAINT "aggregation_annotation_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "aggregation_annotation" ADD CONSTRAINT "aggregation_annotation_fk_annotation_id" FOREIGN KEY ("annotation_id")
  REFERENCES "annotation" ("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

