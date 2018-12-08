-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/38/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/39/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN preferred_language varchar(8);

;

COMMIT;

