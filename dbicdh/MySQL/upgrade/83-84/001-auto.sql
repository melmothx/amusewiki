-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/84/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `bookcover` (
  `bookcover_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title` varchar(255) NOT NULL DEFAULT '',
  `coverheight` integer NOT NULL DEFAULT 210,
  `coverwidth` integer NOT NULL DEFAULT 148,
  `spinewidth` integer NOT NULL DEFAULT 0,
  `flapwidth` integer NOT NULL DEFAULT 0,
  `wrapwidth` integer NOT NULL DEFAULT 0,
  `bleedwidth` integer NOT NULL DEFAULT 10,
  `marklength` integer NOT NULL DEFAULT 5,
  `foldingmargin` smallint NOT NULL DEFAULT 0,
  `created` datetime NOT NULL,
  `compiled` datetime NULL,
  `zip_path` varchar(255) NULL,
  `pdf_path` varchar(255) NULL,
  `template` varchar(64) NULL,
  `font_name` varchar(255) NULL,
  `language_code` varchar(8) NULL,
  `comments` text NULL,
  `session_id` varchar(255) NULL,
  `user_id` integer NULL,
  INDEX `bookcover_idx_site_id` (`site_id`),
  INDEX `bookcover_idx_user_id` (`user_id`),
  PRIMARY KEY (`bookcover_id`),
  CONSTRAINT `bookcover_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bookcover_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `bookcover_token` (
  `bookcover_id` integer NOT NULL,
  `token_name` varchar(255) NOT NULL,
  `token_value` text NULL,
  INDEX `bookcover_token_idx_bookcover_id` (`bookcover_id`),
  INDEX `bookcover_token_name_amw_index` (`token_name`),
  PRIMARY KEY (`bookcover_id`, `token_name`),
  CONSTRAINT `bookcover_token_fk_bookcover_id` FOREIGN KEY (`bookcover_id`) REFERENCES `bookcover` (`bookcover_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

