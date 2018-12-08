-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `legacy_link` (
  `site_id` varchar(16) NOT NULL,
  `legacy_path` varchar(255) NOT NULL,
  `new_path` varchar(255) NOT NULL,
  INDEX `legacy_link_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `legacy_path`),
  CONSTRAINT `legacy_link_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

