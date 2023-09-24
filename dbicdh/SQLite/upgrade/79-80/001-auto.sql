-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/79/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/80/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE attachment ADD COLUMN errors text;

;

COMMIT;

