-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/64/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/65/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN publisher text;

;
ALTER TABLE title ADD COLUMN isbn text;

;
ALTER TABLE title ADD COLUMN rights text;

;
ALTER TABLE title ADD COLUMN seriesname text;

;
ALTER TABLE title ADD COLUMN seriesnumber text;

;

COMMIT;

