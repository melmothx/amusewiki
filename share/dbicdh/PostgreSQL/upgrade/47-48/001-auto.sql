-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/47/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/48/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE category ADD COLUMN active smallint DEFAULT 1 NOT NULL;

;

COMMIT;

