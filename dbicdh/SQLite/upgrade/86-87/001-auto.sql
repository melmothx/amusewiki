-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/86/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/87/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE oai_pmh_record ADD COLUMN aggregation_series_id integer;

;
ALTER TABLE oai_pmh_record ADD COLUMN aggregation_id integer;

;
CREATE INDEX oai_pmh_record_idx_aggregation_id ON oai_pmh_record (aggregation_id);

;
CREATE INDEX oai_pmh_record_idx_aggregation_series_id ON oai_pmh_record (aggregation_series_id);

;

;

;

COMMIT;

