-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `aggregation` (
  `aggregation_id` integer NOT NULL auto_increment,
  `aggregation_code` varchar(255) NOT NULL,
  `aggregation_uri` varchar(255) NOT NULL,
  `aggregation_name` varchar(255) NOT NULL,
  `series_number` varchar(255) NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `publication_place` varchar(255) NULL,
  `publication_date` varchar(255) NULL,
  `isbn` varchar(32) NULL,
  `publisher` varchar(255) NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `aggregation_idx_site_id` (`site_id`),
  INDEX `aggregation_uri_amw_index` (`aggregation_uri`),
  INDEX `aggregation_code_amw_index` (`aggregation_code`),
  PRIMARY KEY (`aggregation_id`),
  UNIQUE `aggregation_uri_site_id_unique` (`aggregation_uri`, `site_id`),
  CONSTRAINT `aggregation_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `aggregation_title` (
  `aggregation_id` integer NOT NULL,
  `title_uri` varchar(255) NOT NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  INDEX `aggregation_title_idx_aggregation_id` (`aggregation_id`),
  INDEX `aggregation_title_uri_amw_index` (`title_uri`),
  PRIMARY KEY (`aggregation_id`, `title_uri`),
  CONSTRAINT `aggregation_title_fk_aggregation_id` FOREIGN KEY (`aggregation_id`) REFERENCES `aggregation` (`aggregation_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

