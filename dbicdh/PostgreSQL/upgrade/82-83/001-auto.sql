-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation_series" (
  "aggregation_series_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "aggregation_series_uri" character varying(255) NOT NULL,
  "aggregation_series_name" character varying(255) NOT NULL,
  "publisher" character varying(255),
  "publication_place" character varying(255),
  PRIMARY KEY ("aggregation_series_id"),
  CONSTRAINT "aggregation_series_uri_site_id_unique" UNIQUE ("aggregation_series_uri", "site_id")
);
CREATE INDEX "aggregation_series_idx_site_id" on "aggregation_series" ("site_id");

;
ALTER TABLE "aggregation_series" ADD CONSTRAINT "aggregation_series_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
DROP INDEX "aggregation_code_amw_index";

;
ALTER TABLE "aggregation" DROP COLUMN "aggregation_code";

;
ALTER TABLE "aggregation" DROP COLUMN "series_number";

;
ALTER TABLE "aggregation" ADD COLUMN "aggregation_series_id" integer;

;
ALTER TABLE "aggregation" ADD COLUMN "publication_date_year" integer;

;
ALTER TABLE "aggregation" ADD COLUMN "publication_date_month" integer;

;
ALTER TABLE "aggregation" ADD COLUMN "publication_date_day" integer;

;
ALTER TABLE "aggregation" ADD COLUMN "issue" character varying(255);

;
ALTER TABLE "aggregation" ALTER COLUMN "aggregation_name" DROP NOT NULL;

;
CREATE INDEX "aggregation_idx_aggregation_series_id" on "aggregation" ("aggregation_series_id");

;
ALTER TABLE "aggregation" ADD CONSTRAINT "aggregation_fk_aggregation_series_id" FOREIGN KEY ("aggregation_series_id")
  REFERENCES "aggregation_series" ("aggregation_series_id") ON DELETE SET NULL ON UPDATE CASCADE;

;

COMMIT;

