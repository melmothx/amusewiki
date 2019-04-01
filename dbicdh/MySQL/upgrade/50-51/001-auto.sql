-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `tag` (
  `tag_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `parent_tag_id` integer NULL,
  INDEX `tag_idx_parent_tag_id` (`parent_tag_id`),
  INDEX `tag_idx_site_id` (`site_id`),
  PRIMARY KEY (`tag_id`),
  UNIQUE `site_id_uri_unique` (`site_id`, `uri`),
  CONSTRAINT `tag_fk_parent_tag_id` FOREIGN KEY (`parent_tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `tag_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `tag_body` (
  `tag_id` integer NOT NULL,
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `title_muse` text NULL,
  `title_html` text NULL,
  `body_muse` text NULL,
  `body_html` text NULL,
  INDEX `tag_body_idx_tag_id` (`tag_id`),
  PRIMARY KEY (`tag_id`, `lang`),
  CONSTRAINT `tag_body_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `tag_category` (
  `tag_id` integer NOT NULL,
  `category_id` integer NOT NULL,
  INDEX `tag_category_idx_category_id` (`category_id`),
  INDEX `tag_category_idx_tag_id` (`tag_id`),
  PRIMARY KEY (`tag_id`, `category_id`),
  CONSTRAINT `tag_category_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `tag_category_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `tag_title` (
  `tag_id` integer NOT NULL,
  `title_id` integer NOT NULL,
  INDEX `tag_title_idx_tag_id` (`tag_id`),
  INDEX `tag_title_idx_title_id` (`title_id`),
  PRIMARY KEY (`tag_id`, `title_id`),
  CONSTRAINT `tag_title_fk_tag_id` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`tag_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `tag_title_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

