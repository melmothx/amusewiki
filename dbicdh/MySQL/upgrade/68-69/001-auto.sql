-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/68/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/69/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `custom_formats` ADD COLUMN `bb_linespacing` integer NOT NULL DEFAULT 0;

;

COMMIT;

