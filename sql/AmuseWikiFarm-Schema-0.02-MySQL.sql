-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sat Mar  8 11:20:45 2014
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `site`;

--
-- Table: `site`
--
CREATE TABLE `site` (
  `id` varchar(8) NOT NULL,
  `locale` varchar(3) NOT NULL DEFAULT 'en',
  `sitename` varchar(255) NOT NULL DEFAULT '',
  `siteslogan` varchar(255) NOT NULL DEFAULT '',
  `logo` varchar(32) NULL,
  `mail` varchar(128) NULL,
  `canonical` varchar(255) NOT NULL DEFAULT '',
  `tex` integer NOT NULL DEFAULT 1,
  `pdf` integer NOT NULL DEFAULT 1,
  `a4_pdf` integer NOT NULL DEFAULT 1,
  `lt_pdf` integer NOT NULL DEFAULT 1,
  `html` integer NOT NULL DEFAULT 1,
  `bare_html` integer NOT NULL DEFAULT 1,
  `epub` integer NOT NULL DEFAULT 1,
  `zip` integer NOT NULL DEFAULT 1,
  `ttdir` text NOT NULL DEFAULT '',
  `papersize` varchar(64) NOT NULL DEFAULT '',
  `division` integer NOT NULL DEFAULT 12,
  `bcor` varchar(16) NOT NULL DEFAULT '0mm',
  `fontsize` integer NOT NULL DEFAULT 10,
  `mainfont` varchar(255) NOT NULL DEFAULT 'Linux Libertine O',
  `twoside` integer NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `attachment`;

--
-- Table: `attachment`
--
CREATE TABLE `attachment` (
  `id` integer NOT NULL auto_increment,
  `f_path` text NOT NULL,
  `f_name` varchar(255) NOT NULL,
  `f_archive_rel_path` varchar(4) NOT NULL,
  `f_timestamp` varchar(255) NOT NULL,
  `f_full_path_name` text NOT NULL,
  `f_suffix` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `site_id` varchar(8) NOT NULL,
  INDEX `attachment_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_site_id_unique` (`uri`, `site_id`),
  CONSTRAINT `attachment_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `category`;

--
-- Table: `category`
--
CREATE TABLE `category` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `uri` varchar(255) NOT NULL,
  `type` varchar(16) NOT NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `site_id` varchar(8) NOT NULL,
  INDEX `category_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_site_id_type_unique` (`uri`, `site_id`, `type`),
  CONSTRAINT `category_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `title`;

--
-- Table: `title`
--
CREATE TABLE `title` (
  `id` integer NOT NULL auto_increment,
  `title` text NOT NULL DEFAULT '',
  `subtitle` text NOT NULL DEFAULT '',
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `date` text NULL,
  `notes` text NOT NULL DEFAULT '',
  `source` text NOT NULL DEFAULT '',
  `list_title` text NULL,
  `author` text NULL,
  `uid` varchar(255) NULL,
  `attach` varchar(255) NULL,
  `pubdate` timestamp NULL,
  `f_path` text NOT NULL,
  `f_name` varchar(255) NOT NULL,
  `f_archive_rel_path` varchar(4) NOT NULL,
  `f_timestamp` varchar(255) NOT NULL,
  `f_full_path_name` text NOT NULL,
  `f_suffix` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `deleted` text NOT NULL DEFAULT '',
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `site_id` varchar(8) NOT NULL,
  INDEX `title_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_site_id_unique` (`uri`, `site_id`),
  CONSTRAINT `title_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `vhost`;

--
-- Table: `vhost`
--
CREATE TABLE `vhost` (
  `name` varchar(255) NOT NULL,
  `site_id` varchar(8) NULL,
  INDEX `vhost_idx_site_id` (`site_id`),
  PRIMARY KEY (`name`),
  CONSTRAINT `vhost_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `title_category`;

--
-- Table: `title_category`
--
CREATE TABLE `title_category` (
  `title_id` integer NOT NULL,
  `category_id` integer NOT NULL,
  INDEX `title_category_idx_category_id` (`category_id`),
  INDEX `title_category_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `category_id`),
  CONSTRAINT `title_category_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_category_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

