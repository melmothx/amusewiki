-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/77/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/78/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `oai_pmh_record` (
  `identifier` text NOT NULL,
  `datestamp` datetime NULL,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NULL,
  `attachment_id` integer NULL,
  `custom_formats_id` integer NULL,
  `metadata_identifier` text NULL,
  `metadata_type` varchar(32) NULL,
  `metadata_format` varchar(32) NULL,
  `deleted` integer(1) NOT NULL DEFAULT 0,
  INDEX `oai_pmh_record_idx_attachment_id` (`attachment_id`),
  INDEX `oai_pmh_record_idx_custom_formats_id` (`custom_formats_id`),
  INDEX `oai_pmh_record_idx_site_id` (`site_id`),
  INDEX `oai_pmh_record_idx_title_id` (`title_id`),
  PRIMARY KEY (`identifier`),
  CONSTRAINT `oai_pmh_record_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `oai_pmh_record_fk_custom_formats_id` FOREIGN KEY (`custom_formats_id`) REFERENCES `custom_formats` (`custom_formats_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `oai_pmh_record_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `oai_pmh_record_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `oai_pmh_record_set` (
  `oai_pmh_record_id` text NOT NULL,
  `oai_pmh_set_id` varchar(255) NOT NULL,
  INDEX `oai_pmh_record_set_idx_oai_pmh_record_id` (`oai_pmh_record_id`),
  INDEX `oai_pmh_record_set_idx_oai_pmh_set_id` (`oai_pmh_set_id`),
  PRIMARY KEY (`oai_pmh_record_id`, `oai_pmh_set_id`),
  CONSTRAINT `oai_pmh_record_set_fk_oai_pmh_record_id` FOREIGN KEY (`oai_pmh_record_id`) REFERENCES `oai_pmh_record` (`identifier`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `oai_pmh_record_set_fk_oai_pmh_set_id` FOREIGN KEY (`oai_pmh_set_id`) REFERENCES `oai_pmh_set` (`set_spec`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `oai_pmh_set` (
  `set_spec` varchar(255) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `set_name` text NULL,
  INDEX `oai_pmh_set_idx_site_id` (`site_id`),
  PRIMARY KEY (`set_spec`),
  CONSTRAINT `oai_pmh_set_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

