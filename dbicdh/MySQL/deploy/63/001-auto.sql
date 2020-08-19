--
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Aug 12 08:10:30 2020
--
;
SET foreign_key_checks=0;
--
-- Table: `column_comments`
--
CREATE TABLE `column_comments` (
  `table_name` varchar(255) NULL,
  `column_name` varchar(255) NULL,
  `comment_text` text NULL
);
--
-- Table: `roles`
--
CREATE TABLE `roles` (
  `id` integer NOT NULL auto_increment,
  `role` varchar(128) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `role_unique` (`role`)
) ENGINE=InnoDB;
--
-- Table: `site`
--
CREATE TABLE `site` (
  `id` varchar(16) NOT NULL,
  `mode` varchar(16) NOT NULL DEFAULT 'private',
  `locale` varchar(3) NOT NULL DEFAULT 'en',
  `magic_question` varchar(255) NOT NULL DEFAULT '12 + 4 =',
  `magic_answer` varchar(255) NOT NULL DEFAULT '16',
  `fixed_category_list` text NULL,
  `sitename` varchar(255) NOT NULL DEFAULT '',
  `siteslogan` varchar(255) NOT NULL DEFAULT '',
  `theme` varchar(32) NOT NULL DEFAULT '',
  `logo` varchar(255) NOT NULL DEFAULT '',
  `mail_notify` text NULL,
  `mail_from` text NULL,
  `canonical` varchar(255) NOT NULL,
  `secure_site` integer(1) NOT NULL DEFAULT 1,
  `secure_site_only` integer(1) NOT NULL DEFAULT 0,
  `sitegroup` varchar(255) NOT NULL DEFAULT '',
  `cgit_integration` integer(1) NOT NULL DEFAULT 1,
  `ssl_key` varchar(255) NOT NULL DEFAULT '',
  `ssl_cert` varchar(255) NOT NULL DEFAULT '',
  `ssl_ca_cert` varchar(255) NOT NULL DEFAULT '',
  `ssl_chained_cert` varchar(255) NOT NULL DEFAULT '',
  `acme_certificate` integer(1) NOT NULL DEFAULT 0,
  `multilanguage` varchar(255) NOT NULL DEFAULT '',
  `active` integer(1) NOT NULL DEFAULT 1,
  `blog_style` integer(1) NOT NULL DEFAULT 0,
  `bb_page_limit` integer NOT NULL DEFAULT 1000,
  `tex` integer(1) NOT NULL DEFAULT 1,
  `pdf` integer(1) NOT NULL DEFAULT 1,
  `a4_pdf` integer(1) NOT NULL DEFAULT 0,
  `lt_pdf` integer(1) NOT NULL DEFAULT 0,
  `sl_pdf` integer(1) NOT NULL DEFAULT 0,
  `html` integer(1) NOT NULL DEFAULT 1,
  `bare_html` integer(1) NOT NULL DEFAULT 1,
  `epub` integer(1) NOT NULL DEFAULT 1,
  `zip` integer(1) NOT NULL DEFAULT 1,
  `ttdir` varchar(255) NOT NULL DEFAULT '',
  `papersize` varchar(64) NOT NULL DEFAULT '',
  `division` integer NOT NULL DEFAULT 12,
  `bcor` varchar(16) NOT NULL DEFAULT '0mm',
  `fontsize` integer NOT NULL DEFAULT 10,
  `mainfont` varchar(255) NOT NULL DEFAULT 'CMU Serif',
  `sansfont` varchar(255) NOT NULL DEFAULT 'CMU Sans Serif',
  `monofont` varchar(255) NOT NULL DEFAULT 'CMU Typewriter Text',
  `beamertheme` varchar(255) NOT NULL DEFAULT 'default',
  `beamercolortheme` varchar(255) NOT NULL DEFAULT 'dove',
  `nocoverpage` integer(1) NOT NULL DEFAULT 0,
  `logo_with_sitename` integer(1) NOT NULL DEFAULT 0,
  `opening` varchar(16) NOT NULL DEFAULT 'any',
  `twoside` integer(1) NOT NULL DEFAULT 0,
  `binary_upload_max_size_in_mega` integer NOT NULL DEFAULT 8,
  `git_token` text NULL,
  `last_updated` datetime NULL,
  PRIMARY KEY (`id`),
  UNIQUE `canonical_unique` (`canonical`)
) ENGINE=InnoDB;
--
-- Table: `table_comments`
--
CREATE TABLE `table_comments` (
  `table_name` varchar(255) NULL,
  `comment_text` text NULL
);
--
-- Table: `users`
--
CREATE TABLE `users` (
  `id` integer NOT NULL auto_increment,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(255) NULL,
  `created_by` varchar(255) NULL,
  `active` integer(1) NOT NULL DEFAULT 1,
  `edit_option_preview_box_height` integer NOT NULL DEFAULT 500,
  `edit_option_show_filters` integer(1) NOT NULL DEFAULT 1,
  `edit_option_show_cheatsheet` integer(1) NOT NULL DEFAULT 1,
  `edit_option_page_left_bs_columns` integer NULL DEFAULT 6,
  `preferred_language` varchar(8) NULL,
  `reset_token` text NULL,
  `reset_until` integer NULL,
  PRIMARY KEY (`id`),
  UNIQUE `username_unique` (`username`)
) ENGINE=InnoDB;
--
-- Table: `amw_session`
--
CREATE TABLE `amw_session` (
  `session_id` varchar(255) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `expires` integer NULL,
  `session_data` blob NULL,
  `flash_data` blob NULL,
  `generic_data` blob NULL,
  INDEX `amw_session_idx_site_id` (`site_id`),
  PRIMARY KEY (`session_id`, `site_id`),
  CONSTRAINT `amw_session_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `attachment`
--
CREATE TABLE `attachment` (
  `id` integer NOT NULL auto_increment,
  `f_path` text NOT NULL,
  `f_name` varchar(255) NOT NULL,
  `f_archive_rel_path` varchar(32) NOT NULL,
  `f_timestamp` datetime NOT NULL,
  `f_timestamp_epoch` integer NOT NULL DEFAULT 0,
  `f_full_path_name` text NOT NULL,
  `f_suffix` varchar(16) NOT NULL,
  `f_class` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `title_muse` text NULL,
  `comment_muse` text NULL,
  `title_html` text NULL,
  `comment_html` text NULL,
  `mime_type` varchar(255) NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `attachment_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_site_id_unique` (`uri`, `site_id`),
  CONSTRAINT `attachment_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `bookbuilder_profile`
--
CREATE TABLE `bookbuilder_profile` (
  `bookbuilder_profile_id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `profile_name` varchar(255) NOT NULL,
  `profile_data` text NOT NULL,
  INDEX `bookbuilder_profile_idx_user_id` (`user_id`),
  PRIMARY KEY (`bookbuilder_profile_id`),
  CONSTRAINT `bookbuilder_profile_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `bookbuilder_session`
--
CREATE TABLE `bookbuilder_session` (
  `bookbuilder_session_id` integer NOT NULL auto_increment,
  `token` varchar(16) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `bb_data` text NOT NULL,
  `last_updated` datetime NOT NULL,
  INDEX `bookbuilder_session_idx_site_id` (`site_id`),
  PRIMARY KEY (`bookbuilder_session_id`),
  CONSTRAINT `bookbuilder_session_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `bulk_job`
--
CREATE TABLE `bulk_job` (
  `bulk_job_id` integer NOT NULL auto_increment,
  `task` varchar(32) NULL,
  `created` datetime NOT NULL,
  `started` datetime NULL,
  `completed` datetime NULL,
  `site_id` varchar(16) NOT NULL,
  `status` varchar(32) NULL,
  `username` varchar(255) NULL,
  INDEX `bulk_job_idx_site_id` (`site_id`),
  PRIMARY KEY (`bulk_job_id`),
  CONSTRAINT `bulk_job_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `category`
--
CREATE TABLE `category` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `uri` varchar(255) NOT NULL,
  `type` varchar(16) NOT NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `text_count` integer NOT NULL DEFAULT 0,
  `active` smallint NOT NULL DEFAULT 1,
  `site_id` varchar(16) NOT NULL,
  INDEX `category_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_site_id_type_unique` (`uri`, `site_id`, `type`),
  CONSTRAINT `category_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `custom_formats`
--
CREATE TABLE `custom_formats` (
  `custom_formats_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `format_name` varchar(255) NOT NULL,
  `format_description` text NULL,
  `format_alias` varchar(8) NULL,
  `format_code` varchar(8) NULL,
  `format_priority` integer NOT NULL DEFAULT 0,
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
  `bb_coverpage_only_if_toc` smallint NULL DEFAULT 0,
  `bb_nofinalpage` smallint NULL DEFAULT 0,
  `bb_notoc` smallint NULL DEFAULT 0,
  `bb_impressum` smallint NULL DEFAULT 0,
  `bb_sansfontsections` smallint NULL DEFAULT 0,
  `bb_nobold` smallint NULL DEFAULT 0,
  `bb_secondary_footnotes_alpha` smallint NULL DEFAULT 0,
  `bb_start_with_empty_page` smallint NULL DEFAULT 0,
  `bb_continuefootnotes` smallint NULL DEFAULT 0,
  `bb_centerchapter` smallint NULL DEFAULT 0,
  `bb_centersection` smallint NULL DEFAULT 0,
  `bb_opening` varchar(16) NOT NULL DEFAULT 'any',
  `bb_papersize` varchar(255) NOT NULL DEFAULT 'generic',
  `bb_paper_height` integer NOT NULL DEFAULT 0,
  `bb_paper_width` integer NOT NULL DEFAULT 0,
  `bb_schema` varchar(255) NOT NULL DEFAULT '2up',
  `bb_signature` integer NOT NULL DEFAULT 0,
  `bb_signature_2up` varchar(8) NOT NULL DEFAULT '40-80',
  `bb_signature_4up` varchar(8) NOT NULL DEFAULT '40-80',
  `bb_twoside` smallint NULL DEFAULT 0,
  `bb_unbranded` smallint NULL DEFAULT 0,
  `bb_areaset_height` integer NOT NULL DEFAULT 0,
  `bb_areaset_width` integer NOT NULL DEFAULT 0,
  `bb_fussy_last_word` smallint NULL DEFAULT 0,
  `bb_tex_emergencystretch` integer NOT NULL DEFAULT 30,
  `bb_tex_tolerance` integer NOT NULL DEFAULT 200,
  `bb_ignore_cover` smallint NULL DEFAULT 0,
  INDEX `custom_formats_idx_site_id` (`site_id`),
  PRIMARY KEY (`custom_formats_id`),
  UNIQUE `site_id_format_alias_unique` (`site_id`, `format_alias`),
  UNIQUE `site_id_format_code_unique` (`site_id`, `format_code`),
  CONSTRAINT `custom_formats_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `include_path`
--
CREATE TABLE `include_path` (
  `include_path_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `directory` text NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  INDEX `include_path_idx_site_id` (`site_id`),
  PRIMARY KEY (`include_path_id`),
  CONSTRAINT `include_path_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `legacy_link`
--
CREATE TABLE `legacy_link` (
  `site_id` varchar(16) NOT NULL,
  `legacy_path` varchar(255) NOT NULL,
  `new_path` varchar(255) NOT NULL,
  INDEX `legacy_link_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `legacy_path`),
  CONSTRAINT `legacy_link_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `monthly_archive`
--
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
--
-- Table: `node`
--
CREATE TABLE `node` (
  `node_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `full_path` text NULL,
  `parent_node_id` integer NULL,
  INDEX `node_idx_parent_node_id` (`parent_node_id`),
  INDEX `node_idx_site_id` (`site_id`),
  PRIMARY KEY (`node_id`),
  UNIQUE `site_id_uri_unique` (`site_id`, `uri`),
  CONSTRAINT `node_fk_parent_node_id` FOREIGN KEY (`parent_node_id`) REFERENCES `node` (`node_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `node_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `redirection`
--
CREATE TABLE `redirection` (
  `id` integer NOT NULL auto_increment,
  `uri` varchar(255) NOT NULL,
  `type` varchar(16) NOT NULL,
  `redirect` varchar(255) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `redirection_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_type_site_id_unique` (`uri`, `type`, `site_id`),
  CONSTRAINT `redirection_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `site_category_type`
--
CREATE TABLE `site_category_type` (
  `site_id` varchar(16) NOT NULL,
  `category_type` varchar(16) NOT NULL,
  `active` smallint NOT NULL DEFAULT 1,
  `priority` integer NOT NULL DEFAULT 0,
  `name_singular` varchar(255) NOT NULL,
  `name_plural` varchar(255) NOT NULL,
  INDEX `site_category_type_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `category_type`),
  CONSTRAINT `site_category_type_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `site_link`
--
CREATE TABLE `site_link` (
  `url` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `menu` varchar(32) NOT NULL DEFAULT 'specials',
  `site_id` varchar(16) NOT NULL,
  INDEX `site_link_idx_site_id` (`site_id`),
  CONSTRAINT `site_link_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `site_options`
--
CREATE TABLE `site_options` (
  `site_id` varchar(16) NOT NULL,
  `option_name` varchar(64) NOT NULL,
  `option_value` text NULL,
  INDEX `site_options_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `option_name`),
  CONSTRAINT `site_options_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `title`
--
CREATE TABLE `title` (
  `id` integer NOT NULL auto_increment,
  `title` text NULL,
  `subtitle` text NULL,
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `date` text NULL,
  `notes` text NULL,
  `source` text NULL,
  `list_title` text NULL,
  `author` text NULL,
  `uid` varchar(255) NOT NULL DEFAULT '',
  `attach` text NULL,
  `pubdate` datetime NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'unpublished',
  `parent` varchar(255) NULL,
  `f_path` text NOT NULL,
  `f_name` varchar(255) NOT NULL,
  `f_archive_rel_path` varchar(32) NOT NULL,
  `f_timestamp` datetime NOT NULL,
  `f_timestamp_epoch` integer NOT NULL DEFAULT 0,
  `f_full_path_name` text NOT NULL,
  `f_suffix` varchar(16) NOT NULL,
  `f_class` varchar(16) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `deleted` text NULL,
  `slides` integer(1) NOT NULL DEFAULT 0,
  `text_structure` text NULL,
  `cover` varchar(255) NOT NULL DEFAULT '',
  `teaser` text NULL,
  `sorting_pos` integer NOT NULL DEFAULT 0,
  `sku` varchar(64) NOT NULL DEFAULT '',
  `text_qualification` varchar(255) NULL,
  `text_size` integer NOT NULL DEFAULT 0,
  `attachment_index` integer NOT NULL DEFAULT 0,
  `blob_container` integer(1) NOT NULL DEFAULT 0,
  `site_id` varchar(16) NOT NULL,
  INDEX `title_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `uri_f_class_site_id_unique` (`uri`, `f_class`, `site_id`),
  CONSTRAINT `title_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `vhost`
--
CREATE TABLE `vhost` (
  `name` varchar(255) NOT NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `vhost_idx_site_id` (`site_id`),
  PRIMARY KEY (`name`),
  CONSTRAINT `vhost_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `whitelist_ip`
--
CREATE TABLE `whitelist_ip` (
  `site_id` varchar(16) NOT NULL,
  `ip` varchar(64) NOT NULL,
  `user_editable` smallint NOT NULL DEFAULT 0,
  INDEX `whitelist_ip_idx_site_id` (`site_id`),
  PRIMARY KEY (`site_id`, `ip`),
  CONSTRAINT `whitelist_ip_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `category_description`
--
CREATE TABLE `category_description` (
  `category_description_id` integer NOT NULL auto_increment,
  `muse_body` text NULL,
  `html_body` text NULL,
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `last_modified_by` varchar(255) NULL,
  `category_id` integer NOT NULL,
  INDEX `category_description_idx_category_id` (`category_id`),
  PRIMARY KEY (`category_description_id`),
  UNIQUE `category_id_lang_unique` (`category_id`, `lang`),
  CONSTRAINT `category_description_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `global_site_files`
--
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
--
-- Table: `included_file`
--
CREATE TABLE `included_file` (
  `included_file_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NOT NULL,
  `file_path` text NOT NULL,
  `file_timestamp` datetime NULL,
  `file_epoch` integer NULL,
  INDEX `included_file_idx_site_id` (`site_id`),
  INDEX `included_file_idx_title_id` (`title_id`),
  PRIMARY KEY (`included_file_id`),
  CONSTRAINT `included_file_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `included_file_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `job`
--
CREATE TABLE `job` (
  `id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `bulk_job_id` integer NULL,
  `task` varchar(32) NULL,
  `payload` text NULL,
  `status` varchar(32) NULL,
  `created` datetime NOT NULL,
  `started` datetime NULL,
  `completed` datetime NULL,
  `priority` integer NOT NULL DEFAULT 10,
  `produced` varchar(255) NULL,
  `username` varchar(255) NULL,
  `errors` text NULL,
  INDEX `job_idx_bulk_job_id` (`bulk_job_id`),
  INDEX `job_idx_site_id` (`site_id`),
  INDEX `job_status_index` (`status`),
  PRIMARY KEY (`id`),
  CONSTRAINT `job_fk_bulk_job_id` FOREIGN KEY (`bulk_job_id`) REFERENCES `bulk_job` (`bulk_job_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `job_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `muse_header`
--
CREATE TABLE `muse_header` (
  `title_id` integer NOT NULL,
  `muse_header` varchar(255) NOT NULL,
  `muse_value` text NULL,
  INDEX `muse_header_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `muse_header`),
  CONSTRAINT `muse_header_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `node_body`
--
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
--
-- Table: `revision`
--
CREATE TABLE `revision` (
  `id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NOT NULL,
  `f_full_path_name` text NULL,
  `message` text NULL,
  `status` varchar(16) NOT NULL DEFAULT 'editing',
  `session_id` varchar(255) NULL,
  `username` varchar(255) NULL,
  `updated` datetime NOT NULL,
  INDEX `revision_idx_site_id` (`site_id`),
  INDEX `revision_idx_title_id` (`title_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `revision_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `revision_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `text_internal_link`
--
CREATE TABLE `text_internal_link` (
  `title_id` integer NOT NULL,
  `site_id` varchar(16) NOT NULL,
  `f_class` varchar(255) NOT NULL,
  `uri` varchar(255) NOT NULL,
  `full_link` text NOT NULL,
  INDEX `text_internal_link_idx_site_id` (`site_id`),
  INDEX `text_internal_link_idx_title_id` (`title_id`),
  CONSTRAINT `text_internal_link_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `text_internal_link_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `text_part`
--
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
--
-- Table: `title_stat`
--
CREATE TABLE `title_stat` (
  `title_stat_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title_id` integer NOT NULL,
  `accessed` datetime NOT NULL,
  `user_agent` text NULL,
  `type` text NULL,
  INDEX `title_stat_idx_site_id` (`site_id`),
  INDEX `title_stat_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_stat_id`),
  CONSTRAINT `title_stat_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_stat_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_role`
--
CREATE TABLE `user_role` (
  `user_id` integer NOT NULL,
  `role_id` integer NOT NULL,
  INDEX `user_role_idx_role_id` (`role_id`),
  INDEX `user_role_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `role_id`),
  CONSTRAINT `user_role_fk_role_id` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_role_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_site`
--
CREATE TABLE `user_site` (
  `user_id` integer NOT NULL,
  `site_id` varchar(16) NOT NULL,
  INDEX `user_site_idx_site_id` (`site_id`),
  INDEX `user_site_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `site_id`),
  CONSTRAINT `user_site_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_site_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `job_file`
--
CREATE TABLE `job_file` (
  `filename` varchar(255) NOT NULL,
  `slot` varchar(255) NOT NULL DEFAULT '',
  `job_id` integer NOT NULL,
  INDEX `job_file_idx_job_id` (`job_id`),
  PRIMARY KEY (`filename`),
  CONSTRAINT `job_file_fk_job_id` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `node_category`
--
CREATE TABLE `node_category` (
  `node_id` integer NOT NULL,
  `category_id` integer NOT NULL,
  INDEX `node_category_idx_category_id` (`category_id`),
  INDEX `node_category_idx_node_id` (`node_id`),
  PRIMARY KEY (`node_id`, `category_id`),
  CONSTRAINT `node_category_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_category_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `node_title`
--
CREATE TABLE `node_title` (
  `node_id` integer NOT NULL,
  `title_id` integer NOT NULL,
  INDEX `node_title_idx_node_id` (`node_id`),
  INDEX `node_title_idx_title_id` (`title_id`),
  PRIMARY KEY (`node_id`, `title_id`),
  CONSTRAINT `node_title_fk_node_id` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `node_title_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `text_month`
--
CREATE TABLE `text_month` (
  `title_id` integer NOT NULL,
  `monthly_archive_id` integer NOT NULL,
  INDEX `text_month_idx_monthly_archive_id` (`monthly_archive_id`),
  INDEX `text_month_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `monthly_archive_id`),
  CONSTRAINT `text_month_fk_monthly_archive_id` FOREIGN KEY (`monthly_archive_id`) REFERENCES `monthly_archive` (`monthly_archive_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `text_month_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `title_attachment`
--
CREATE TABLE `title_attachment` (
  `title_id` integer NOT NULL,
  `attachment_id` integer NOT NULL,
  INDEX `title_attachment_idx_attachment_id` (`attachment_id`),
  INDEX `title_attachment_idx_title_id` (`title_id`),
  PRIMARY KEY (`title_id`, `attachment_id`),
  CONSTRAINT `title_attachment_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `title_attachment_fk_title_id` FOREIGN KEY (`title_id`) REFERENCES `title` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
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
