-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/52/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE node ADD COLUMN sorting_pos integer DEFAULT 0 NOT NULL;

;

COMMIT;

