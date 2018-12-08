-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/29/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE bulk_job ADD COLUMN started datetime NULL;

;

COMMIT;

