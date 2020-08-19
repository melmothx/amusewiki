-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `included_file` (
  `included_file_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NOT NULL,
  `file_path` text NOT NULL,
  `file_timestamp` datetime NULL,
  `file_epoch` integer NULL,
  INDEX `included_file_idx_site_id` (`site_id`),
  INDEX `included_file_idx_title_id` (`title_id`),
  PRIMARY KEY (`included_file_id`),
  CONSTRAINT `included_file_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `included_file_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

