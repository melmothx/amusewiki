-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/76/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/77/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `attachment` ADD COLUMN `alt_text` text NULL;

;

COMMIT;

