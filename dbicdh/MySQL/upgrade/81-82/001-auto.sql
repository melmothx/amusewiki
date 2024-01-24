-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `aggregation` (
  `aggregation_id` integer NOT NULL auto_increment,
  `aggregation_series_id` integer NULL,
  `aggregation_uri` varchar(255) NOT NULL,
  `aggregation_name` varchar(255) NULL,
  `publication_date` varchar(255) NULL,
  `publication_date_year` integer NULL,
  `publication_date_month` integer NULL,
  `publication_date_day` integer NULL,
  `issue` varchar(255) NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `publication_place` varchar(255) NULL,
  `publisher` varchar(255) NULL,
  `isbn` varchar(32) NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `aggregation_idx_aggregation_series_id` (`aggregation_series_id`),
  INDEX `aggregation_idx_site_id` (`site_id`),
  INDEX `aggregation_uri_amw_index` (`aggregation_uri`),
  PRIMARY KEY (`aggregation_id`),
  UNIQUE `aggregation_uri_site_id_unique` (`aggregation_uri`, `site_id`),
  CONSTRAINT `aggregation_fk_aggregation_series_id` FOREIGN KEY (`aggregation_series_id`) REFERENCES `aggregation_series` (`aggregation_series_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `aggregation_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `aggregation_annotation` (
  `annotation_id` integer NOT NULL,
  `aggregation_id` integer NOT NULL,
  `annotation_value` text NULL,
  INDEX `aggregation_annotation_idx_aggregation_id` (`aggregation_id`),
  INDEX `aggregation_annotation_idx_annotation_id` (`annotation_id`),
  PRIMARY KEY (`annotation_id`, `aggregation_id`),
  CONSTRAINT `aggregation_annotation_fk_aggregation_id` FOREIGN KEY (`aggregation_id`) REFERENCES `aggregation` (`aggregation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `aggregation_annotation_fk_annotation_id` FOREIGN KEY (`annotation_id`) REFERENCES `annotation` (`annotation_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

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
CREATE TABLE `node_aggregation` (
  `node_id` integer NOT NULL,
  `aggregation_id` integer NOT NULL,
  INDEX `node_aggregation_idx_aggregation_id` (`aggregation_id`),
  INDEX `node_aggregation_idx_node_id` (`node_id`),
  PRIMARY KEY (`node_id`, `aggregation_id`),
  CONSTRAINT `node_aggregation_fk_aggregation_id` FOREIGN KEY (`aggregation_id`) REFERENCES `aggregation` (`aggregation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_aggregation_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `node_aggregation_series` (
  `node_id` integer NOT NULL,
  `aggregation_series_id` integer NOT NULL,
  INDEX `node_aggregation_series_idx_aggregation_series_id` (`aggregation_series_id`),
  INDEX `node_aggregation_series_idx_node_id` (`node_id`),
  PRIMARY KEY (`node_id`, `aggregation_series_id`),
  CONSTRAINT `node_aggregation_series_fk_aggregation_series_id` FOREIGN KEY (`aggregation_series_id`) REFERENCES `aggregation_series` (`aggregation_series_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_aggregation_series_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

