-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/64/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/65/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `title` ADD COLUMN `publisher` text NULL,
                    ADD COLUMN `isbn` text NULL,
                    ADD COLUMN `rights` text NULL,
                    ADD COLUMN `seriesname` text NULL,
                    ADD COLUMN `seriesnumber` text NULL;

;

COMMIT;

