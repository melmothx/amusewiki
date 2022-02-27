-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/70/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/71/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `mirror_info` (
  `mirror_info_id` integer NOT NULL auto_increment,
  `title_id` integer NULL,
  `attachment_id` integer NULL,
  `mirror_origin_id` integer NULL,
  `site_id` varchar(16) NOT NULL,
  `checksum` varchar(128) NULL,
  `download_source` text NULL,
  `download_destination` text NULL,
  `mirror_exception` varchar(32) NOT NULL DEFAULT '',
  `last_updated` datetime NULL,
  INDEX `mirror_info_idx_attachment_id` (`attachment_id`),
  INDEX `mirror_info_idx_mirror_origin_id` (`mirror_origin_id`),
  INDEX `mirror_info_idx_site_id` (`site_id`),
  INDEX `mirror_info_idx_title_id` (`title_id`),
  PRIMARY KEY (`mirror_info_id`),
  UNIQUE `attachment_id_unique` (`attachment_id`),
  UNIQUE `title_id_unique` (`title_id`),
  CONSTRAINT `mirror_info_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mirror_info_fk_mirror_origin_id` FOREIGN KEY (`mirror_origin_id`) REFERENCES `mirror_origin` (`mirror_origin_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `mirror_info_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `mirror_info_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `mirror_origin` (
  `mirror_origin_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `remote_domain` varchar(255) NOT NULL,
  `remote_path` varchar(255) NOT NULL,
  `active` integer(1) NOT NULL DEFAULT 0,
  `status_message` text NULL,
  `last_downloaded` datetime NULL,
  INDEX `mirror_origin_idx_site_id` (`site_id`),
  PRIMARY KEY (`mirror_origin_id`),
  CONSTRAINT `mirror_origin_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE `bulk_job` ADD COLUMN `payload` text NULL,
                       ADD COLUMN `produced` varchar(255) NULL;

;

COMMIT;

