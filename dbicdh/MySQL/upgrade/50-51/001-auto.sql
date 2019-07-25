-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `node` (
  `node_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `parent_node_id` integer NULL,
  INDEX `node_idx_parent_node_id` (`parent_node_id`),
  INDEX `node_idx_site_id` (`site_id`),
  PRIMARY KEY (`node_id`),
  UNIQUE `site_id_uri_unique` (`site_id`, `uri`),
  CONSTRAINT `node_fk_parent_node_id` FOREIGN KEY (`parent_node_id`) REFERENCES `node` (`node_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `node_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `node_body` (
  `node_id` integer NOT NULL,
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `title_muse` text NULL,
  `title_html` text NULL,
  `body_muse` text NULL,
  `body_html` text NULL,
  INDEX `node_body_idx_node_id` (`node_id`),
  PRIMARY KEY (`node_id`, `lang`),
  CONSTRAINT `node_body_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `node_category` (
  `node_id` integer NOT NULL,
  `category_id` integer NOT NULL,
  INDEX `node_category_idx_category_id` (`category_id`),
  INDEX `node_category_idx_node_id` (`node_id`),
  PRIMARY KEY (`node_id`, `category_id`),
  CONSTRAINT `node_category_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_category_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `node_title` (
  `node_id` integer NOT NULL,
  `title_id` integer NOT NULL,
  INDEX `node_title_idx_node_id` (`node_id`),
  INDEX `node_title_idx_title_id` (`title_id`),
  PRIMARY KEY (`node_id`, `title_id`),
  CONSTRAINT `node_title_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_title_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

