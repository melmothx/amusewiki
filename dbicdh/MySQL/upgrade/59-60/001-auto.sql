-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `whitelist_ip` (
  `site_id` varchar(16) NOT NULL,
  `ip` varchar(64) NOT NULL,
  INDEX `whitelist_ip_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `ip`),
  CONSTRAINT `whitelist_ip_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

