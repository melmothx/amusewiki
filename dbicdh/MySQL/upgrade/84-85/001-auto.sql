-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/85/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `aggregation` ADD COLUMN `comment_muse` text NULL,
                          ADD COLUMN `comment_html` text NULL;

;
ALTER TABLE `aggregation_series` ADD COLUMN `comment_muse` text NULL,
                                 ADD COLUMN `comment_html` text NULL;

;
ALTER TABLE `bookcover_token` ADD COLUMN `sorting_pos` integer NOT NULL DEFAULT 0;

;

COMMIT;

