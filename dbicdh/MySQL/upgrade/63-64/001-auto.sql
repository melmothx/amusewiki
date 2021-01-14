-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/64/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `title` CHANGE COLUMN `text_qualification` `text_qualification` varchar(32) NULL;

;

COMMIT;

