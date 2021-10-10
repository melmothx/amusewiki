-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/67/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `global_site_files` DROP PRIMARY KEY,
                                CHANGE COLUMN `file_type` `file_type` varchar(255) NOT NULL,
                                ADD PRIMARY KEY (`site_id`, `file_name`, `file_type`);

;

COMMIT;

