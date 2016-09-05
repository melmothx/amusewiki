-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `bookbuilder_session` (
  `bookbuilder_session_id` integer NOT NULL auto_increment,
  `token` varchar(16) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `bb_data` text NOT NULL DEFAULT '{}',
  `last_updated` datetime NOT NULL,
  INDEX `bookbuilder_session_idx_site_id` (`site_id`),
  PRIMARY KEY (`bookbuilder_session_id`),
  CONSTRAINT `bookbuilder_session_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

