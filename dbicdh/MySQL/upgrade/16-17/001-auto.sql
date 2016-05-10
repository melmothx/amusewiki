-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/16/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `title_stat` (
  `title_stat_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NOT NULL,
  `accessed` datetime NOT NULL,
  `notes` text NULL,
  INDEX `title_stat_idx_site_id` (`site_id`),
  INDEX `title_stat_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_stat_id`),
  CONSTRAINT `title_stat_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_stat_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

