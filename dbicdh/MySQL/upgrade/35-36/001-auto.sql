-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/35/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `backlink` (
  `title_linked_to` integer NOT NULL,
  `title_linked_from` integer NOT NULL,
  INDEX `backlink_idx_title_linked_from` (`title_linked_from`),
  INDEX `backlink_idx_title_linked_to` (`title_linked_to`),
  PRIMARY KEY (`title_linked_to`, `title_linked_from`),
  CONSTRAINT `backlink_fk_title_linked_from` FOREIGN KEY (`title_linked_from`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `backlink_fk_title_linked_to` FOREIGN KEY (`title_linked_to`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

