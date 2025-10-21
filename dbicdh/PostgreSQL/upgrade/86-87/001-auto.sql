-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/86/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/87/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "oai_pmh_record" ADD COLUMN "aggregation_series_id" integer;

;
ALTER TABLE "oai_pmh_record" ADD COLUMN "aggregation_id" integer;

;
CREATE INDEX "oai_pmh_record_idx_aggregation_id" on "oai_pmh_record" ("aggregation_id");

;
CREATE INDEX "oai_pmh_record_idx_aggregation_series_id" on "oai_pmh_record" ("aggregation_series_id");

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_aggregation_id" FOREIGN KEY ("aggregation_id")
  REFERENCES "aggregation" ("aggregation_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_aggregation_series_id" FOREIGN KEY ("aggregation_series_id")
  REFERENCES "aggregation_series" ("aggregation_series_id") ON DELETE SET NULL ON UPDATE CASCADE;

;

COMMIT;

