-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/75/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/76/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `site_category_type` ADD COLUMN `description` text NULL;

;

COMMIT;

