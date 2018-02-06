-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/45/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/46/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `amw_session` (
  `session_id` varchar(255) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `expires` integer NULL,
  `session_data` blob NULL,
  `flash_data` blob NULL,
  `generic_data` blob NULL,
  INDEX `amw_session_idx_site_id` (`site_id`),
  PRIMARY KEY (`session_id`, `site_id`),
  CONSTRAINT `amw_session_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

