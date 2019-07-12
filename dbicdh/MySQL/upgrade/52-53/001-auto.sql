-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/52/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/53/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE node ADD COLUMN full_path text NULL;

;

COMMIT;

