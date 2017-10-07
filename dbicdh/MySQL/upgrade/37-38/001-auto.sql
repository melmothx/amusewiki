-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/37/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `text_part` (
  `title_id` integer NOT NULL,
  `part_index` varchar(16) NOT NULL,
  `part_level` integer NOT NULL,
  `part_title` text NOT NULL,
  `part_size` integer NOT NULL,
  `toc_index` integer NOT NULL,
  `part_order` integer NOT NULL,
  INDEX `text_part_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `part_index`),
  CONSTRAINT `text_part_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE title ADD COLUMN text_qualification varchar(255) NULL,
                  ADD COLUMN text_size integer NOT NULL DEFAULT 0;

;

COMMIT;

