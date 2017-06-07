-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/34/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN bb_nofinalpage smallint DEFAULT 0;

;

COMMIT;

