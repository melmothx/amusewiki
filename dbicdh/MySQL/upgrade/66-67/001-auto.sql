-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/66/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/67/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `custom_formats` ADD COLUMN `bb_geometry_top_margin` integer NOT NULL DEFAULT 0,
                             ADD COLUMN `bb_geometry_outer_margin` integer NOT NULL DEFAULT 0;

;

COMMIT;

