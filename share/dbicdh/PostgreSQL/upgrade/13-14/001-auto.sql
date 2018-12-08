-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/13/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN last_updated timestamp;

;

COMMIT;

