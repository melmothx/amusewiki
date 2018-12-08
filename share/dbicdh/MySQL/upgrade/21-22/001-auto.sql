-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `monthly_archive` (
  `monthly_archive_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `month` integer(2) NOT NULL,
  `year` integer(4) NOT NULL,
  INDEX `monthly_archive_idx_site_id` (`site_id`),
  PRIMARY KEY (`monthly_archive_id`),
  UNIQUE `site_id_month_year_unique` (`site_id`, `month`, `year`),
  CONSTRAINT `monthly_archive_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `text_month` (
  `title_id` integer NOT NULL,
  `monthly_archive_id` integer NOT NULL,
  INDEX `text_month_idx_monthly_archive_id` (`monthly_archive_id`),
  INDEX `text_month_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `monthly_archive_id`),
  CONSTRAINT `text_month_fk_monthly_archive_id` FOREIGN KEY (`monthly_archive_id`) REFERENCES `monthly_archive` (`monthly_archive_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `text_month_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

