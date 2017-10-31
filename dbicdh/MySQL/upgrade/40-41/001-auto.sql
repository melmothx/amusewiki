-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `global_site_files` (
  `site_id` varchar(16) NOT NULL,
  `attachment_id` integer NULL,
  `file_name` varchar(255) NOT NULL,
  `file_type` varchar(255) NOT NULL,
  `file_path` text NOT NULL,
  `image_width` integer NULL,
  `image_height` integer NULL,
  INDEX `global_site_files_idx_attachment_id` (`attachment_id`),
  INDEX `global_site_files_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `file_name`),
  CONSTRAINT `global_site_files_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `global_site_files_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

