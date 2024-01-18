-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation_annotation" (
  "annotation_id" integer NOT NULL,
  "aggregation_id" integer NOT NULL,
  "annotation_value" text,
  PRIMARY KEY ("annotation_id", "aggregation_id"),
  FOREIGN KEY ("aggregation_id") REFERENCES "aggregation"("aggregation_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("annotation_id") REFERENCES "annotation"("annotation_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_annotation_idx_aggregation_id" ON "aggregation_annotation" ("aggregation_id");

;
CREATE INDEX "aggregation_annotation_idx_annotation_id" ON "aggregation_annotation" ("annotation_id");

;

COMMIT;

