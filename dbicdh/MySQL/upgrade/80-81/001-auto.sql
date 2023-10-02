-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/80/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `annotation` (
  `annotation_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `annotation_name` varchar(255) NOT NULL,
  `annotation_type` varchar(32) NOT NULL,
  `label` varchar(255) NOT NULL DEFAULT '',
  `priority` integer NOT NULL DEFAULT 0,
  `active` integer(1) NOT NULL DEFAULT 1,
  `private` integer(1) NOT NULL DEFAULT 0,
  INDEX `annotation_idx_site_id` (`site_id`),
  PRIMARY KEY (`annotation_id`),
  UNIQUE `site_id_annotation_name_unique` (`site_id`, `annotation_name`),
  CONSTRAINT `annotation_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `title_annotation` (
  `annotation_id` integer NOT NULL,
  `title_id` integer NOT NULL,
  `annotation_value` text NULL,
  INDEX `title_annotation_idx_annotation_id` (`annotation_id`),
  INDEX `title_annotation_idx_title_id` (`title_id`),
  PRIMARY KEY (`annotation_id`, `title_id`),
  CONSTRAINT `title_annotation_fk_annotation_id` FOREIGN KEY (`annotation_id`) REFERENCES `annotation` (`annotation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_annotation_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE `oai_pmh_record` ADD COLUMN `metadata_format_description` varchar(255) NULL;

;
ALTER TABLE `title` ADD COLUMN `datefirst` text NULL;

;

COMMIT;

