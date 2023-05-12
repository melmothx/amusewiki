-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/79/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE oai_pmh_record ADD COLUMN update_run integer NOT NULL DEFAULT 0;

;

COMMIT;

