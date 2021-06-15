-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/65/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `custom_formats` CHANGE COLUMN `bb_beamercolortheme` `bb_beamercolortheme` varchar(32) NOT NULL DEFAULT 'dove',
                             CHANGE COLUMN `bb_beamertheme` `bb_beamertheme` varchar(32) NOT NULL DEFAULT 'default',
                             CHANGE COLUMN `bb_crop_papersize` `bb_crop_papersize` varchar(32) NOT NULL DEFAULT 'a4',
                             CHANGE COLUMN `bb_headings` `bb_headings` varchar(64) NOT NULL DEFAULT '0',
                             CHANGE COLUMN `bb_papersize` `bb_papersize` varchar(32) NOT NULL DEFAULT 'generic',
                             CHANGE COLUMN `bb_schema` `bb_schema` varchar(64) NOT NULL DEFAULT '2up';

;

COMMIT;

