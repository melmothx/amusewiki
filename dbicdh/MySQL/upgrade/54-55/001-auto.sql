-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/54/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/55/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `title_attachment` (
  `title_id` integer NOT NULL,
  `attachment_id` integer NOT NULL,
  INDEX `title_attachment_idx_attachment_id` (`attachment_id`),
  INDEX `title_attachment_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `attachment_id`),
  CONSTRAINT `title_attachment_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_attachment_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

