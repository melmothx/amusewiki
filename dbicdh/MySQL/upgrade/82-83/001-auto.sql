-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `aggregation_series` (
  `aggregation_series_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `aggregation_series_uri` varchar(255) NOT NULL,
  `aggregation_series_name` varchar(255) NOT NULL,
  `publisher` varchar(255) NULL,
  `publication_place` varchar(255) NULL,
  INDEX `aggregation_series_idx_site_id` (`site_id`),
  PRIMARY KEY (`aggregation_series_id`),
  UNIQUE `aggregation_series_uri_site_id_unique` (`aggregation_series_uri`, `site_id`),
  CONSTRAINT `aggregation_series_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE `aggregation` DROP INDEX aggregation_code_amw_index,
                          DROP COLUMN `aggregation_code`,
                          DROP COLUMN `series_number`,
                          ADD COLUMN `aggregation_series_id` integer NULL,
                          ADD COLUMN `publication_date_year` integer NULL,
                          ADD COLUMN `publication_date_month` integer NULL,
                          ADD COLUMN `publication_date_day` integer NULL,
                          ADD COLUMN `issue` varchar(255) NULL,
                          CHANGE COLUMN `aggregation_name` `aggregation_name` varchar(255) NULL,
                          ADD INDEX `aggregation_idx_aggregation_series_id` (`aggregation_series_id`),
                          ADD CONSTRAINT `aggregation_fk_aggregation_series_id` FOREIGN KEY (`aggregation_series_id`) REFERENCES `aggregation_series` (`aggregation_series_id`) ON DELETE SET NULL ON UPDATE CASCADE;

;

COMMIT;

