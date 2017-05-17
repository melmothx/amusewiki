-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `muse_header` (
  `title_id` integer NOT NULL,
  `muse_header` varchar(255) NOT NULL,
  `muse_value` text NULL,
  INDEX `muse_header_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `muse_header`),
  CONSTRAINT `muse_header_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

