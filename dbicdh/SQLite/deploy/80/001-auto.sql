--
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Sep 24 07:46:07 2023
--

;
BEGIN TRANSACTION;
--
-- Table: "column_comments"
--
CREATE TABLE "column_comments" (
  "table_name" varchar(255),
  "column_name" varchar(255),
  "comment_text" text
);
--
-- Table: "roles"
--
CREATE TABLE "roles" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "role" varchar(128)
);
CREATE UNIQUE INDEX "role_unique" ON "roles" ("role");
--
-- Table: "site"
--
CREATE TABLE "site" (
  "id" varchar(16) NOT NULL,
  "mode" varchar(16) NOT NULL DEFAULT 'private',
  "locale" varchar(3) NOT NULL DEFAULT 'en',
  "magic_question" varchar(255) NOT NULL DEFAULT '12 + 4 =',
  "magic_answer" varchar(255) NOT NULL DEFAULT '16',
  "fixed_category_list" text,
  "sitename" varchar(255) NOT NULL DEFAULT '',
  "siteslogan" varchar(255) NOT NULL DEFAULT '',
  "theme" varchar(32) NOT NULL DEFAULT '',
  "logo" varchar(255) NOT NULL DEFAULT '',
  "mail_notify" text,
  "mail_from" text,
  "canonical" varchar(255) NOT NULL,
  "secure_site" integer(1) NOT NULL DEFAULT 1,
  "secure_site_only" integer(1) NOT NULL DEFAULT 0,
  "sitegroup" varchar(255) NOT NULL DEFAULT '',
  "cgit_integration" integer(1) NOT NULL DEFAULT 1,
  "ssl_key" varchar(255) NOT NULL DEFAULT '',
  "ssl_cert" varchar(255) NOT NULL DEFAULT '',
  "ssl_ca_cert" varchar(255) NOT NULL DEFAULT '',
  "ssl_chained_cert" varchar(255) NOT NULL DEFAULT '',
  "acme_certificate" integer(1) NOT NULL DEFAULT 0,
  "multilanguage" varchar(255) NOT NULL DEFAULT '',
  "active" integer(1) NOT NULL DEFAULT 1,
  "blog_style" integer(1) NOT NULL DEFAULT 0,
  "bb_page_limit" integer NOT NULL DEFAULT 1000,
  "tex" integer(1) NOT NULL DEFAULT 1,
  "pdf" integer(1) NOT NULL DEFAULT 1,
  "a4_pdf" integer(1) NOT NULL DEFAULT 0,
  "lt_pdf" integer(1) NOT NULL DEFAULT 0,
  "sl_pdf" integer(1) NOT NULL DEFAULT 0,
  "html" integer(1) NOT NULL DEFAULT 1,
  "bare_html" integer(1) NOT NULL DEFAULT 1,
  "epub" integer(1) NOT NULL DEFAULT 1,
  "zip" integer(1) NOT NULL DEFAULT 1,
  "ttdir" varchar(255) NOT NULL DEFAULT '',
  "papersize" varchar(64) NOT NULL DEFAULT '',
  "division" integer NOT NULL DEFAULT 12,
  "bcor" varchar(16) NOT NULL DEFAULT '0mm',
  "fontsize" integer NOT NULL DEFAULT 10,
  "mainfont" varchar(255) NOT NULL DEFAULT 'CMU Serif',
  "sansfont" varchar(255) NOT NULL DEFAULT 'CMU Sans Serif',
  "monofont" varchar(255) NOT NULL DEFAULT 'CMU Typewriter Text',
  "beamertheme" varchar(255) NOT NULL DEFAULT 'default',
  "beamercolortheme" varchar(255) NOT NULL DEFAULT 'dove',
  "nocoverpage" integer(1) NOT NULL DEFAULT 0,
  "logo_with_sitename" integer(1) NOT NULL DEFAULT 0,
  "opening" varchar(16) NOT NULL DEFAULT 'any',
  "twoside" integer(1) NOT NULL DEFAULT 0,
  "binary_upload_max_size_in_mega" integer NOT NULL DEFAULT 8,
  "git_token" text,
  "last_updated" datetime,
  PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "canonical_unique" ON "site" ("canonical");
--
-- Table: "table_comments"
--
CREATE TABLE "table_comments" (
  "table_name" varchar(255),
  "comment_text" text
);
--
-- Table: "users"
--
CREATE TABLE "users" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "username" varchar(255) NOT NULL,
  "password" varchar(255) NOT NULL,
  "email" varchar(255),
  "created_by" varchar(255),
  "active" integer(1) NOT NULL DEFAULT 1,
  "edit_option_preview_box_height" integer NOT NULL DEFAULT 500,
  "edit_option_show_filters" integer(1) NOT NULL DEFAULT 1,
  "edit_option_show_cheatsheet" integer(1) NOT NULL DEFAULT 1,
  "edit_option_page_left_bs_columns" integer DEFAULT 6,
  "preferred_language" varchar(8),
  "reset_token" text,
  "reset_until" integer
);
CREATE UNIQUE INDEX "username_unique" ON "users" ("username");
--
-- Table: "amw_session"
--
CREATE TABLE "amw_session" (
  "session_id" varchar(255) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "expires" integer,
  "session_data" blob,
  "flash_data" blob,
  "generic_data" blob,
  PRIMARY KEY ("session_id", "site_id"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "amw_session_idx_site_id" ON "amw_session" ("site_id");
--
-- Table: "attachment"
--
CREATE TABLE "attachment" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "f_path" text NOT NULL,
  "f_name" varchar(255) NOT NULL,
  "f_archive_rel_path" varchar(32) NOT NULL,
  "f_timestamp" datetime NOT NULL,
  "f_timestamp_epoch" integer NOT NULL DEFAULT 0,
  "f_full_path_name" text NOT NULL,
  "f_suffix" varchar(16) NOT NULL,
  "f_class" varchar(16) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "title_muse" text,
  "comment_muse" text,
  "title_html" text,
  "comment_html" text,
  "alt_text" text,
  "mime_type" varchar(255),
  "errors" text,
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "attachment_idx_site_id" ON "attachment" ("site_id");
CREATE UNIQUE INDEX "uri_site_id_unique" ON "attachment" ("uri", "site_id");
--
-- Table: "bookbuilder_profile"
--
CREATE TABLE "bookbuilder_profile" (
  "bookbuilder_profile_id" INTEGER PRIMARY KEY NOT NULL,
  "user_id" integer NOT NULL,
  "profile_name" varchar(255) NOT NULL,
  "profile_data" text NOT NULL,
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "bookbuilder_profile_idx_user_id" ON "bookbuilder_profile" ("user_id");
--
-- Table: "bookbuilder_session"
--
CREATE TABLE "bookbuilder_session" (
  "bookbuilder_session_id" INTEGER PRIMARY KEY NOT NULL,
  "token" varchar(16) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "bb_data" text NOT NULL,
  "last_updated" datetime NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "bookbuilder_session_idx_site_id" ON "bookbuilder_session" ("site_id");
--
-- Table: "bulk_job"
--
CREATE TABLE "bulk_job" (
  "bulk_job_id" INTEGER PRIMARY KEY NOT NULL,
  "task" varchar(32),
  "created" datetime NOT NULL,
  "started" datetime,
  "completed" datetime,
  "site_id" varchar(16) NOT NULL,
  "status" varchar(32),
  "payload" text,
  "produced" varchar(255),
  "username" varchar(255),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "bulk_job_idx_site_id" ON "bulk_job" ("site_id");
--
-- Table: "category"
--
CREATE TABLE "category" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" text,
  "uri" varchar(255) NOT NULL,
  "type" varchar(16) NOT NULL,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "text_count" integer NOT NULL DEFAULT 0,
  "active" smallint NOT NULL DEFAULT 1,
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "category_idx_site_id" ON "category" ("site_id");
CREATE UNIQUE INDEX "uri_site_id_type_unique" ON "category" ("uri", "site_id", "type");
--
-- Table: "custom_formats"
--
CREATE TABLE "custom_formats" (
  "custom_formats_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "format_name" varchar(255) NOT NULL,
  "format_description" text,
  "format_alias" varchar(8),
  "format_code" varchar(8),
  "format_priority" integer NOT NULL DEFAULT 0,
  "active" smallint DEFAULT 1,
  "bb_format" varchar(16) NOT NULL DEFAULT 'pdf',
  "bb_epub_embed_fonts" smallint DEFAULT 1,
  "bb_bcor" integer NOT NULL DEFAULT 0,
  "bb_beamercolortheme" varchar(32) NOT NULL DEFAULT 'dove',
  "bb_beamertheme" varchar(32) NOT NULL DEFAULT 'default',
  "bb_cover" smallint DEFAULT 1,
  "bb_crop_marks" smallint DEFAULT 0,
  "bb_crop_papersize" varchar(32) NOT NULL DEFAULT 'a4',
  "bb_crop_paper_height" integer NOT NULL DEFAULT 0,
  "bb_crop_paper_width" integer NOT NULL DEFAULT 0,
  "bb_crop_paper_thickness" varchar(16) NOT NULL DEFAULT '0.10mm',
  "bb_division" integer NOT NULL DEFAULT 12,
  "bb_fontsize" integer NOT NULL DEFAULT 10,
  "bb_headings" varchar(64) NOT NULL DEFAULT '0',
  "bb_imposed" smallint DEFAULT 0,
  "bb_mainfont" varchar(255),
  "bb_sansfont" varchar(255),
  "bb_monofont" varchar(255),
  "bb_nocoverpage" smallint DEFAULT 0,
  "bb_coverpage_only_if_toc" smallint DEFAULT 0,
  "bb_nofinalpage" smallint DEFAULT 0,
  "bb_notoc" smallint DEFAULT 0,
  "bb_impressum" smallint DEFAULT 0,
  "bb_sansfontsections" smallint DEFAULT 0,
  "bb_nobold" smallint DEFAULT 0,
  "bb_secondary_footnotes_alpha" smallint DEFAULT 0,
  "bb_start_with_empty_page" smallint DEFAULT 0,
  "bb_continuefootnotes" smallint DEFAULT 0,
  "bb_centerchapter" smallint DEFAULT 0,
  "bb_centersection" smallint DEFAULT 0,
  "bb_opening" varchar(16) NOT NULL DEFAULT 'any',
  "bb_papersize" varchar(32) NOT NULL DEFAULT 'generic',
  "bb_paper_height" integer NOT NULL DEFAULT 0,
  "bb_paper_width" integer NOT NULL DEFAULT 0,
  "bb_schema" varchar(64) NOT NULL DEFAULT '2up',
  "bb_signature" integer NOT NULL DEFAULT 0,
  "bb_signature_2up" varchar(8) NOT NULL DEFAULT '40-80',
  "bb_signature_4up" varchar(8) NOT NULL DEFAULT '40-80',
  "bb_twoside" smallint DEFAULT 0,
  "bb_unbranded" smallint DEFAULT 0,
  "bb_areaset_height" integer NOT NULL DEFAULT 0,
  "bb_areaset_width" integer NOT NULL DEFAULT 0,
  "bb_geometry_top_margin" integer NOT NULL DEFAULT 0,
  "bb_geometry_outer_margin" integer NOT NULL DEFAULT 0,
  "bb_fussy_last_word" smallint DEFAULT 0,
  "bb_tex_emergencystretch" integer NOT NULL DEFAULT 30,
  "bb_tex_tolerance" integer NOT NULL DEFAULT 200,
  "bb_ignore_cover" smallint DEFAULT 0,
  "bb_linespacing" integer NOT NULL DEFAULT 0,
  "bb_parindent" integer NOT NULL DEFAULT 15,
  "bb_body_only" smallint DEFAULT 0,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "custom_formats_idx_site_id" ON "custom_formats" ("site_id");
CREATE UNIQUE INDEX "site_id_format_alias_unique" ON "custom_formats" ("site_id", "format_alias");
CREATE UNIQUE INDEX "site_id_format_code_unique" ON "custom_formats" ("site_id", "format_code");
--
-- Table: "include_path"
--
CREATE TABLE "include_path" (
  "include_path_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "directory" text,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "include_path_idx_site_id" ON "include_path" ("site_id");
--
-- Table: "legacy_link"
--
CREATE TABLE "legacy_link" (
  "site_id" varchar(16) NOT NULL,
  "legacy_path" varchar(255) NOT NULL,
  "new_path" varchar(255) NOT NULL,
  PRIMARY KEY ("site_id", "legacy_path"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "legacy_link_idx_site_id" ON "legacy_link" ("site_id");
--
-- Table: "mirror_origin"
--
CREATE TABLE "mirror_origin" (
  "mirror_origin_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "remote_domain" varchar(255) NOT NULL,
  "remote_path" varchar(255) NOT NULL,
  "active" integer(1) NOT NULL DEFAULT 0,
  "status_message" text,
  "last_downloaded" datetime,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "mirror_origin_idx_site_id" ON "mirror_origin" ("site_id");
--
-- Table: "monthly_archive"
--
CREATE TABLE "monthly_archive" (
  "monthly_archive_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "month" integer(2) NOT NULL,
  "year" integer(4) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "monthly_archive_idx_site_id" ON "monthly_archive" ("site_id");
CREATE UNIQUE INDEX "site_id_month_year_unique" ON "monthly_archive" ("site_id", "month", "year");
--
-- Table: "node"
--
CREATE TABLE "node" (
  "node_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "canonical_title" varchar(255) NOT NULL DEFAULT '',
  "last_updated_epoch" integer NOT NULL DEFAULT 0,
  "last_updated_dt" datetime,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "full_path" text,
  "parent_node_id" integer,
  FOREIGN KEY ("parent_node_id") REFERENCES "node"("node_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "node_idx_parent_node_id" ON "node" ("parent_node_id");
CREATE INDEX "node_idx_site_id" ON "node" ("site_id");
CREATE UNIQUE INDEX "site_id_uri_unique" ON "node" ("site_id", "uri");
--
-- Table: "oai_pmh_set"
--
CREATE TABLE "oai_pmh_set" (
  "oai_pmh_set_id" INTEGER PRIMARY KEY NOT NULL,
  "set_spec" varchar(255) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "set_name" text,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "oai_pmh_set_idx_site_id" ON "oai_pmh_set" ("site_id");
CREATE UNIQUE INDEX "set_spec_site_id_unique" ON "oai_pmh_set" ("set_spec", "site_id");
--
-- Table: "redirection"
--
CREATE TABLE "redirection" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "uri" varchar(255) NOT NULL,
  "type" varchar(16) NOT NULL,
  "redirect" varchar(255) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "redirection_idx_site_id" ON "redirection" ("site_id");
CREATE UNIQUE INDEX "uri_type_site_id_unique" ON "redirection" ("uri", "type", "site_id");
--
-- Table: "site_category_type"
--
CREATE TABLE "site_category_type" (
  "site_id" varchar(16) NOT NULL,
  "category_type" varchar(16) NOT NULL,
  "active" smallint NOT NULL DEFAULT 1,
  "priority" integer NOT NULL DEFAULT 0,
  "name_singular" varchar(255) NOT NULL,
  "name_plural" varchar(255) NOT NULL,
  "generate_index" smallint NOT NULL DEFAULT 1,
  "in_colophon" smallint NOT NULL DEFAULT 0,
  "xapian_custom_slot" smallint,
  "description" text,
  PRIMARY KEY ("site_id", "category_type"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "site_category_type_idx_site_id" ON "site_category_type" ("site_id");
--
-- Table: "site_link"
--
CREATE TABLE "site_link" (
  "url" varchar(255) NOT NULL,
  "label" varchar(255) NOT NULL,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "menu" varchar(32) NOT NULL DEFAULT 'specials',
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "site_link_idx_site_id" ON "site_link" ("site_id");
--
-- Table: "site_options"
--
CREATE TABLE "site_options" (
  "site_id" varchar(16) NOT NULL,
  "option_name" varchar(64) NOT NULL,
  "option_value" text,
  PRIMARY KEY ("site_id", "option_name"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "site_options_idx_site_id" ON "site_options" ("site_id");
--
-- Table: "title"
--
CREATE TABLE "title" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "title" text,
  "subtitle" text,
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "date" text,
  "notes" text,
  "source" text,
  "list_title" text,
  "author" text,
  "uid" varchar(255) NOT NULL DEFAULT '',
  "attach" text,
  "pubdate" datetime NOT NULL,
  "status" varchar(16) NOT NULL DEFAULT 'unpublished',
  "parent" varchar(255),
  "publisher" text,
  "isbn" text,
  "rights" text,
  "seriesname" text,
  "seriesnumber" text,
  "f_path" text NOT NULL,
  "f_name" varchar(255) NOT NULL,
  "f_archive_rel_path" varchar(32) NOT NULL,
  "f_timestamp" datetime NOT NULL,
  "f_timestamp_epoch" integer NOT NULL DEFAULT 0,
  "f_full_path_name" text NOT NULL,
  "f_suffix" varchar(16) NOT NULL,
  "f_class" varchar(16) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "deleted" text,
  "slides" integer(1) NOT NULL DEFAULT 0,
  "text_structure" text,
  "cover" varchar(255) NOT NULL DEFAULT '',
  "teaser" text,
  "sorting_pos" integer NOT NULL DEFAULT 0,
  "sku" varchar(64) NOT NULL DEFAULT '',
  "text_qualification" varchar(32),
  "text_size" integer NOT NULL DEFAULT 0,
  "attachment_index" integer NOT NULL DEFAULT 0,
  "blob_container" integer(1) NOT NULL DEFAULT 0,
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "title_idx_site_id" ON "title" ("site_id");
CREATE UNIQUE INDEX "uri_f_class_site_id_unique" ON "title" ("uri", "f_class", "site_id");
--
-- Table: "vhost"
--
CREATE TABLE "vhost" (
  "name" varchar(255) NOT NULL,
  "site_id" varchar(16) NOT NULL,
  PRIMARY KEY ("name"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "vhost_idx_site_id" ON "vhost" ("site_id");
--
-- Table: "whitelist_ip"
--
CREATE TABLE "whitelist_ip" (
  "site_id" varchar(16) NOT NULL,
  "ip" varchar(64) NOT NULL,
  "user_editable" smallint NOT NULL DEFAULT 0,
  PRIMARY KEY ("site_id", "ip"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "whitelist_ip_idx_site_id" ON "whitelist_ip" ("site_id");
--
-- Table: "category_description"
--
CREATE TABLE "category_description" (
  "category_description_id" INTEGER PRIMARY KEY NOT NULL,
  "muse_body" text,
  "html_body" text,
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "last_modified_by" varchar(255),
  "category_id" integer NOT NULL,
  FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "category_description_idx_category_id" ON "category_description" ("category_id");
CREATE UNIQUE INDEX "category_id_lang_unique" ON "category_description" ("category_id", "lang");
--
-- Table: "global_site_files"
--
CREATE TABLE "global_site_files" (
  "site_id" varchar(16) NOT NULL,
  "attachment_id" integer,
  "file_name" varchar(255) NOT NULL,
  "file_type" varchar(255) NOT NULL,
  "file_path" text NOT NULL,
  "image_width" integer,
  "image_height" integer,
  PRIMARY KEY ("site_id", "file_name", "file_type"),
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "global_site_files_idx_attachment_id" ON "global_site_files" ("attachment_id");
CREATE INDEX "global_site_files_idx_site_id" ON "global_site_files" ("site_id");
--
-- Table: "included_file"
--
CREATE TABLE "included_file" (
  "included_file_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer NOT NULL,
  "file_path" text NOT NULL,
  "file_timestamp" datetime,
  "file_epoch" integer,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "included_file_idx_site_id" ON "included_file" ("site_id");
CREATE INDEX "included_file_idx_title_id" ON "included_file" ("title_id");
--
-- Table: "job"
--
CREATE TABLE "job" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "bulk_job_id" integer,
  "task" varchar(32),
  "payload" text,
  "status" varchar(32),
  "created" datetime NOT NULL,
  "started" datetime,
  "completed" datetime,
  "priority" integer NOT NULL DEFAULT 10,
  "produced" varchar(255),
  "username" varchar(255),
  "errors" text,
  FOREIGN KEY ("bulk_job_id") REFERENCES "bulk_job"("bulk_job_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "job_idx_bulk_job_id" ON "job" ("bulk_job_id");
CREATE INDEX "job_idx_site_id" ON "job" ("site_id");
CREATE INDEX "job_status_index" ON "job" ("status");
--
-- Table: "muse_header"
--
CREATE TABLE "muse_header" (
  "title_id" integer NOT NULL,
  "muse_header" varchar(255) NOT NULL,
  "muse_value" text,
  "muse_value_html" text,
  PRIMARY KEY ("title_id", "muse_header"),
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "muse_header_idx_title_id" ON "muse_header" ("title_id");
--
-- Table: "node_body"
--
CREATE TABLE "node_body" (
  "node_id" integer NOT NULL,
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "title_muse" text,
  "title_html" text,
  "body_muse" text,
  "body_html" text,
  PRIMARY KEY ("node_id", "lang"),
  FOREIGN KEY ("node_id") REFERENCES "node"("node_id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "node_body_idx_node_id" ON "node_body" ("node_id");
--
-- Table: "revision"
--
CREATE TABLE "revision" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer NOT NULL,
  "f_full_path_name" text,
  "message" text,
  "status" varchar(16) NOT NULL DEFAULT 'editing',
  "session_id" varchar(255),
  "username" varchar(255),
  "updated" datetime NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "revision_idx_site_id" ON "revision" ("site_id");
CREATE INDEX "revision_idx_title_id" ON "revision" ("title_id");
--
-- Table: "text_internal_link"
--
CREATE TABLE "text_internal_link" (
  "title_id" integer NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "f_class" varchar(255) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "full_link" text NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "text_internal_link_idx_site_id" ON "text_internal_link" ("site_id");
CREATE INDEX "text_internal_link_idx_title_id" ON "text_internal_link" ("title_id");
--
-- Table: "text_part"
--
CREATE TABLE "text_part" (
  "title_id" integer NOT NULL,
  "part_index" varchar(16) NOT NULL,
  "part_level" integer NOT NULL,
  "part_title" text NOT NULL,
  "part_size" integer NOT NULL,
  "toc_index" integer NOT NULL,
  "part_order" integer NOT NULL,
  PRIMARY KEY ("title_id", "part_index"),
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "text_part_idx_title_id" ON "text_part" ("title_id");
--
-- Table: "title_stat"
--
CREATE TABLE "title_stat" (
  "title_stat_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer NOT NULL,
  "accessed" datetime NOT NULL,
  "user_agent" text,
  "type" text,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "title_stat_idx_site_id" ON "title_stat" ("site_id");
CREATE INDEX "title_stat_idx_title_id" ON "title_stat" ("title_id");
--
-- Table: "user_role"
--
CREATE TABLE "user_role" (
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "role_id"),
  FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "user_role_idx_role_id" ON "user_role" ("role_id");
CREATE INDEX "user_role_idx_user_id" ON "user_role" ("user_id");
--
-- Table: "user_site"
--
CREATE TABLE "user_site" (
  "user_id" integer NOT NULL,
  "site_id" varchar(16) NOT NULL,
  PRIMARY KEY ("user_id", "site_id"),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "user_site_idx_site_id" ON "user_site" ("site_id");
CREATE INDEX "user_site_idx_user_id" ON "user_site" ("user_id");
--
-- Table: "job_file"
--
CREATE TABLE "job_file" (
  "filename" varchar(255) NOT NULL,
  "slot" varchar(255) NOT NULL DEFAULT '',
  "job_id" integer NOT NULL,
  PRIMARY KEY ("filename"),
  FOREIGN KEY ("job_id") REFERENCES "job"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "job_file_idx_job_id" ON "job_file" ("job_id");
--
-- Table: "node_category"
--
CREATE TABLE "node_category" (
  "node_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "category_id"),
  FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("node_id") REFERENCES "node"("node_id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "node_category_idx_category_id" ON "node_category" ("category_id");
CREATE INDEX "node_category_idx_node_id" ON "node_category" ("node_id");
--
-- Table: "node_title"
--
CREATE TABLE "node_title" (
  "node_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "title_id"),
  FOREIGN KEY ("node_id") REFERENCES "node"("node_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "node_title_idx_node_id" ON "node_title" ("node_id");
CREATE INDEX "node_title_idx_title_id" ON "node_title" ("title_id");
--
-- Table: "text_month"
--
CREATE TABLE "text_month" (
  "title_id" integer NOT NULL,
  "monthly_archive_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "monthly_archive_id"),
  FOREIGN KEY ("monthly_archive_id") REFERENCES "monthly_archive"("monthly_archive_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "text_month_idx_monthly_archive_id" ON "text_month" ("monthly_archive_id");
CREATE INDEX "text_month_idx_title_id" ON "text_month" ("title_id");
--
-- Table: "title_attachment"
--
CREATE TABLE "title_attachment" (
  "title_id" integer NOT NULL,
  "attachment_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "attachment_id"),
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "title_attachment_idx_attachment_id" ON "title_attachment" ("attachment_id");
CREATE INDEX "title_attachment_idx_title_id" ON "title_attachment" ("title_id");
--
-- Table: "title_category"
--
CREATE TABLE "title_category" (
  "title_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "category_id"),
  FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "title_category_idx_category_id" ON "title_category" ("category_id");
CREATE INDEX "title_category_idx_title_id" ON "title_category" ("title_id");
--
-- Table: "mirror_info"
--
CREATE TABLE "mirror_info" (
  "mirror_info_id" INTEGER PRIMARY KEY NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "mirror_origin_id" integer,
  "site_id" varchar(16) NOT NULL,
  "checksum" varchar(128),
  "download_source" text,
  "download_destination" text,
  "mirror_exception" varchar(32) NOT NULL DEFAULT '',
  "last_updated" datetime,
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("mirror_origin_id") REFERENCES "mirror_origin"("mirror_origin_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "mirror_info_idx_attachment_id" ON "mirror_info" ("attachment_id");
CREATE INDEX "mirror_info_idx_mirror_origin_id" ON "mirror_info" ("mirror_origin_id");
CREATE INDEX "mirror_info_idx_site_id" ON "mirror_info" ("site_id");
CREATE INDEX "mirror_info_idx_title_id" ON "mirror_info" ("title_id");
CREATE UNIQUE INDEX "attachment_id_unique" ON "mirror_info" ("attachment_id");
CREATE UNIQUE INDEX "title_id_unique" ON "mirror_info" ("title_id");
--
-- Table: "oai_pmh_record"
--
CREATE TABLE "oai_pmh_record" (
  "oai_pmh_record_id" INTEGER PRIMARY KEY NOT NULL,
  "identifier" varchar(255) NOT NULL,
  "datestamp" datetime NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "custom_formats_id" integer,
  "metadata_type" varchar(32),
  "metadata_format" varchar(32),
  "deleted" integer(1) NOT NULL DEFAULT 0,
  "update_run" integer NOT NULL DEFAULT 0,
  FOREIGN KEY ("attachment_id") REFERENCES "attachment"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("custom_formats_id") REFERENCES "custom_formats"("custom_formats_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "oai_pmh_record_idx_attachment_id" ON "oai_pmh_record" ("attachment_id");
CREATE INDEX "oai_pmh_record_idx_custom_formats_id" ON "oai_pmh_record" ("custom_formats_id");
CREATE INDEX "oai_pmh_record_idx_site_id" ON "oai_pmh_record" ("site_id");
CREATE INDEX "oai_pmh_record_idx_title_id" ON "oai_pmh_record" ("title_id");
CREATE UNIQUE INDEX "identifier_site_id_unique" ON "oai_pmh_record" ("identifier", "site_id");
--
-- Table: "oai_pmh_record_set"
--
CREATE TABLE "oai_pmh_record_set" (
  "oai_pmh_record_id" integer NOT NULL,
  "oai_pmh_set_id" integer NOT NULL,
  PRIMARY KEY ("oai_pmh_record_id", "oai_pmh_set_id"),
  FOREIGN KEY ("oai_pmh_record_id") REFERENCES "oai_pmh_record"("oai_pmh_record_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("oai_pmh_set_id") REFERENCES "oai_pmh_set"("oai_pmh_set_id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_record_id" ON "oai_pmh_record_set" ("oai_pmh_record_id");
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_set_id" ON "oai_pmh_record_set" ("oai_pmh_set_id");
COMMIT;
