-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/55/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/56/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `site_category_type` (
  `site_id` varchar(16) NOT NULL,
  `category_type` varchar(16) NOT NULL,
  `active` smallint NOT NULL DEFAULT 1,
  `priority` integer NOT NULL DEFAULT 0,
  `name_singular` varchar(255) NOT NULL,
  `name_plural` varchar(255) NOT NULL,
  INDEX `site_category_type_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `category_type`),
  CONSTRAINT `site_category_type_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

