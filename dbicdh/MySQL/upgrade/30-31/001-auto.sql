-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/30/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `custom_formats` (
  `custom_formats_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `format_name` varchar(255) NOT NULL,
  `format_description` text NULL,
  `active` smallint NULL DEFAULT 1,
  `bb_format` varchar(16) NOT NULL DEFAULT 'pdf',
  `bb_epub_embed_fonts` smallint NULL DEFAULT 1,
  `bb_bcor` integer NOT NULL DEFAULT 0,
  `bb_beamercolortheme` varchar(255) NOT NULL DEFAULT 'dove',
  `bb_beamertheme` varchar(255) NOT NULL DEFAULT 'default',
  `bb_cover` smallint NULL DEFAULT 1,
  `bb_crop_marks` smallint NULL DEFAULT 0,
  `bb_crop_papersize` varchar(255) NOT NULL DEFAULT 'a4',
  `bb_crop_paper_height` integer NOT NULL DEFAULT 0,
  `bb_crop_paper_width` integer NOT NULL DEFAULT 0,
  `bb_crop_paper_thickness` varchar(16) NOT NULL DEFAULT '0.10mm',
  `bb_division` integer NOT NULL DEFAULT 12,
  `bb_fontsize` integer NOT NULL DEFAULT 10,
  `bb_headings` varchar(255) NOT NULL DEFAULT '0',
  `bb_imposed` smallint NULL DEFAULT 0,
  `bb_mainfont` varchar(255) NULL,
  `bb_sansfont` varchar(255) NULL,
  `bb_monofont` varchar(255) NULL,
  `bb_nocoverpage` smallint NULL DEFAULT 0,
  `bb_notoc` smallint NULL DEFAULT 0,
  `bb_opening` varchar(16) NOT NULL DEFAULT 'any',
  `bb_papersize` varchar(255) NOT NULL DEFAULT 'generic',
  `bb_paper_height` integer NOT NULL DEFAULT 0,
  `bb_paper_width` integer NOT NULL DEFAULT 0,
  `bb_schema` varchar(255) NOT NULL DEFAULT '2up',
  `bb_signature` integer NOT NULL DEFAULT 0,
  `bb_twoside` smallint NULL DEFAULT 0,
  `bb_unbranded` smallint NULL DEFAULT 0,
  INDEX `custom_formats_idx_site_id` (`site_id`),
  PRIMARY KEY (`custom_formats_id`),
  CONSTRAINT `custom_formats_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

