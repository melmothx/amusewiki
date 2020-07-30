-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/61/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/62/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `include_path` (
  `include_path_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `directory` text NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  INDEX `include_path_idx_site_id` (`site_id`),
  PRIMARY KEY (`include_path_id`),
  CONSTRAINT `include_path_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

