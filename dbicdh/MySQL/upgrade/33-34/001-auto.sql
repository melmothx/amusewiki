-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/33/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/34/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN sku varchar(64) NOT NULL DEFAULT '';

;

COMMIT;

