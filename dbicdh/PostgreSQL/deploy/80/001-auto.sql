--
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun Sep 24 07:46:08 2023
--
;
--
-- Table: column_comments
--
CREATE TABLE "column_comments" (
  "table_name" character varying(255),
  "column_name" character varying(255),
  "comment_text" text
);

;
--
-- Table: roles
--
CREATE TABLE "roles" (
  "id" serial NOT NULL,
  "role" character varying(128),
  PRIMARY KEY ("id"),
  CONSTRAINT "role_unique" UNIQUE ("role")
);

;
--
-- Table: site
--
CREATE TABLE "site" (
  "id" character varying(16) NOT NULL,
  "mode" character varying(16) DEFAULT 'private' NOT NULL,
  "locale" character varying(3) DEFAULT 'en' NOT NULL,
  "magic_question" character varying(255) DEFAULT '12 + 4 =' NOT NULL,
  "magic_answer" character varying(255) DEFAULT '16' NOT NULL,
  "fixed_category_list" text,
  "sitename" character varying(255) DEFAULT '' NOT NULL,
  "siteslogan" character varying(255) DEFAULT '' NOT NULL,
  "theme" character varying(32) DEFAULT '' NOT NULL,
  "logo" character varying(255) DEFAULT '' NOT NULL,
  "mail_notify" text,
  "mail_from" text,
  "canonical" character varying(255) NOT NULL,
  "secure_site" smallint DEFAULT 1 NOT NULL,
  "secure_site_only" smallint DEFAULT 0 NOT NULL,
  "sitegroup" character varying(255) DEFAULT '' NOT NULL,
  "cgit_integration" smallint DEFAULT 1 NOT NULL,
  "ssl_key" character varying(255) DEFAULT '' NOT NULL,
  "ssl_cert" character varying(255) DEFAULT '' NOT NULL,
  "ssl_ca_cert" character varying(255) DEFAULT '' NOT NULL,
  "ssl_chained_cert" character varying(255) DEFAULT '' NOT NULL,
  "acme_certificate" smallint DEFAULT 0 NOT NULL,
  "multilanguage" character varying(255) DEFAULT '' NOT NULL,
  "active" smallint DEFAULT 1 NOT NULL,
  "blog_style" smallint DEFAULT 0 NOT NULL,
  "bb_page_limit" integer DEFAULT 1000 NOT NULL,
  "tex" smallint DEFAULT 1 NOT NULL,
  "pdf" smallint DEFAULT 1 NOT NULL,
  "a4_pdf" smallint DEFAULT 0 NOT NULL,
  "lt_pdf" smallint DEFAULT 0 NOT NULL,
  "sl_pdf" smallint DEFAULT 0 NOT NULL,
  "html" smallint DEFAULT 1 NOT NULL,
  "bare_html" smallint DEFAULT 1 NOT NULL,
  "epub" smallint DEFAULT 1 NOT NULL,
  "zip" smallint DEFAULT 1 NOT NULL,
  "ttdir" character varying(255) DEFAULT '' NOT NULL,
  "papersize" character varying(64) DEFAULT '' NOT NULL,
  "division" integer DEFAULT 12 NOT NULL,
  "bcor" character varying(16) DEFAULT '0mm' NOT NULL,
  "fontsize" integer DEFAULT 10 NOT NULL,
  "mainfont" character varying(255) DEFAULT 'CMU Serif' NOT NULL,
  "sansfont" character varying(255) DEFAULT 'CMU Sans Serif' NOT NULL,
  "monofont" character varying(255) DEFAULT 'CMU Typewriter Text' NOT NULL,
  "beamertheme" character varying(255) DEFAULT 'default' NOT NULL,
  "beamercolortheme" character varying(255) DEFAULT 'dove' NOT NULL,
  "nocoverpage" smallint DEFAULT 0 NOT NULL,
  "logo_with_sitename" smallint DEFAULT 0 NOT NULL,
  "opening" character varying(16) DEFAULT 'any' NOT NULL,
  "twoside" smallint DEFAULT 0 NOT NULL,
  "binary_upload_max_size_in_mega" integer DEFAULT 8 NOT NULL,
  "git_token" text,
  "last_updated" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "canonical_unique" UNIQUE ("canonical")
);

;
--
-- Table: table_comments
--
CREATE TABLE "table_comments" (
  "table_name" character varying(255),
  "comment_text" text
);

;
--
-- Table: users
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "username" character varying(255) NOT NULL,
  "password" character varying(255) NOT NULL,
  "email" character varying(255),
  "created_by" character varying(255),
  "active" smallint DEFAULT 1 NOT NULL,
  "edit_option_preview_box_height" integer DEFAULT 500 NOT NULL,
  "edit_option_show_filters" smallint DEFAULT 1 NOT NULL,
  "edit_option_show_cheatsheet" smallint DEFAULT 1 NOT NULL,
  "edit_option_page_left_bs_columns" integer DEFAULT 6,
  "preferred_language" character varying(8),
  "reset_token" text,
  "reset_until" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "username_unique" UNIQUE ("username")
);

;
--
-- Table: amw_session
--
CREATE TABLE "amw_session" (
  "session_id" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "expires" integer,
  "session_data" bytea,
  "flash_data" bytea,
  "generic_data" bytea,
  PRIMARY KEY ("session_id", "site_id")
);
CREATE INDEX "amw_session_idx_site_id" on "amw_session" ("site_id");

;
--
-- Table: attachment
--
CREATE TABLE "attachment" (
  "id" serial NOT NULL,
  "f_path" text NOT NULL,
  "f_name" character varying(255) NOT NULL,
  "f_archive_rel_path" character varying(32) NOT NULL,
  "f_timestamp" timestamp NOT NULL,
  "f_timestamp_epoch" integer DEFAULT 0 NOT NULL,
  "f_full_path_name" text NOT NULL,
  "f_suffix" character varying(16) NOT NULL,
  "f_class" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "title_muse" text,
  "comment_muse" text,
  "title_html" text,
  "comment_html" text,
  "alt_text" text,
  "mime_type" character varying(255),
  "errors" text,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_site_id_unique" UNIQUE ("uri", "site_id")
);
CREATE INDEX "attachment_idx_site_id" on "attachment" ("site_id");

;
--
-- Table: bookbuilder_profile
--
CREATE TABLE "bookbuilder_profile" (
  "bookbuilder_profile_id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "profile_name" character varying(255) NOT NULL,
  "profile_data" text NOT NULL,
  PRIMARY KEY ("bookbuilder_profile_id")
);
CREATE INDEX "bookbuilder_profile_idx_user_id" on "bookbuilder_profile" ("user_id");

;
--
-- Table: bookbuilder_session
--
CREATE TABLE "bookbuilder_session" (
  "bookbuilder_session_id" serial NOT NULL,
  "token" character varying(16) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "bb_data" text NOT NULL,
  "last_updated" timestamp NOT NULL,
  PRIMARY KEY ("bookbuilder_session_id")
);
CREATE INDEX "bookbuilder_session_idx_site_id" on "bookbuilder_session" ("site_id");

;
--
-- Table: bulk_job
--
CREATE TABLE "bulk_job" (
  "bulk_job_id" serial NOT NULL,
  "task" character varying(32),
  "created" timestamp NOT NULL,
  "started" timestamp,
  "completed" timestamp,
  "site_id" character varying(16) NOT NULL,
  "status" character varying(32),
  "payload" text,
  "produced" character varying(255),
  "username" character varying(255),
  PRIMARY KEY ("bulk_job_id")
);
CREATE INDEX "bulk_job_idx_site_id" on "bulk_job" ("site_id");

;
--
-- Table: category
--
CREATE TABLE "category" (
  "id" serial NOT NULL,
  "name" text,
  "uri" character varying(255) NOT NULL,
  "type" character varying(16) NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "text_count" integer DEFAULT 0 NOT NULL,
  "active" smallint DEFAULT 1 NOT NULL,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_site_id_type_unique" UNIQUE ("uri", "site_id", "type")
);
CREATE INDEX "category_idx_site_id" on "category" ("site_id");

;
--
-- Table: custom_formats
--
CREATE TABLE "custom_formats" (
  "custom_formats_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "format_name" character varying(255) NOT NULL,
  "format_description" text,
  "format_alias" character varying(8),
  "format_code" character varying(8),
  "format_priority" integer DEFAULT 0 NOT NULL,
  "active" smallint DEFAULT 1,
  "bb_format" character varying(16) DEFAULT 'pdf' NOT NULL,
  "bb_epub_embed_fonts" smallint DEFAULT 1,
  "bb_bcor" integer DEFAULT 0 NOT NULL,
  "bb_beamercolortheme" character varying(32) DEFAULT 'dove' NOT NULL,
  "bb_beamertheme" character varying(32) DEFAULT 'default' NOT NULL,
  "bb_cover" smallint DEFAULT 1,
  "bb_crop_marks" smallint DEFAULT 0,
  "bb_crop_papersize" character varying(32) DEFAULT 'a4' NOT NULL,
  "bb_crop_paper_height" integer DEFAULT 0 NOT NULL,
  "bb_crop_paper_width" integer DEFAULT 0 NOT NULL,
  "bb_crop_paper_thickness" character varying(16) DEFAULT '0.10mm' NOT NULL,
  "bb_division" integer DEFAULT 12 NOT NULL,
  "bb_fontsize" integer DEFAULT 10 NOT NULL,
  "bb_headings" character varying(64) DEFAULT '0' NOT NULL,
  "bb_imposed" smallint DEFAULT 0,
  "bb_mainfont" character varying(255),
  "bb_sansfont" character varying(255),
  "bb_monofont" character varying(255),
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
  "bb_opening" character varying(16) DEFAULT 'any' NOT NULL,
  "bb_papersize" character varying(32) DEFAULT 'generic' NOT NULL,
  "bb_paper_height" integer DEFAULT 0 NOT NULL,
  "bb_paper_width" integer DEFAULT 0 NOT NULL,
  "bb_schema" character varying(64) DEFAULT '2up' NOT NULL,
  "bb_signature" integer DEFAULT 0 NOT NULL,
  "bb_signature_2up" character varying(8) DEFAULT '40-80' NOT NULL,
  "bb_signature_4up" character varying(8) DEFAULT '40-80' NOT NULL,
  "bb_twoside" smallint DEFAULT 0,
  "bb_unbranded" smallint DEFAULT 0,
  "bb_areaset_height" integer DEFAULT 0 NOT NULL,
  "bb_areaset_width" integer DEFAULT 0 NOT NULL,
  "bb_geometry_top_margin" integer DEFAULT 0 NOT NULL,
  "bb_geometry_outer_margin" integer DEFAULT 0 NOT NULL,
  "bb_fussy_last_word" smallint DEFAULT 0,
  "bb_tex_emergencystretch" integer DEFAULT 30 NOT NULL,
  "bb_tex_tolerance" integer DEFAULT 200 NOT NULL,
  "bb_ignore_cover" smallint DEFAULT 0,
  "bb_linespacing" integer DEFAULT 0 NOT NULL,
  "bb_parindent" integer DEFAULT 15 NOT NULL,
  "bb_body_only" smallint DEFAULT 0,
  PRIMARY KEY ("custom_formats_id"),
  CONSTRAINT "site_id_format_alias_unique" UNIQUE ("site_id", "format_alias"),
  CONSTRAINT "site_id_format_code_unique" UNIQUE ("site_id", "format_code")
);
CREATE INDEX "custom_formats_idx_site_id" on "custom_formats" ("site_id");

;
--
-- Table: include_path
--
CREATE TABLE "include_path" (
  "include_path_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "directory" text,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("include_path_id")
);
CREATE INDEX "include_path_idx_site_id" on "include_path" ("site_id");

;
--
-- Table: legacy_link
--
CREATE TABLE "legacy_link" (
  "site_id" character varying(16) NOT NULL,
  "legacy_path" character varying(255) NOT NULL,
  "new_path" character varying(255) NOT NULL,
  PRIMARY KEY ("site_id", "legacy_path")
);
CREATE INDEX "legacy_link_idx_site_id" on "legacy_link" ("site_id");

;
--
-- Table: mirror_origin
--
CREATE TABLE "mirror_origin" (
  "mirror_origin_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "remote_domain" character varying(255) NOT NULL,
  "remote_path" character varying(255) NOT NULL,
  "active" smallint DEFAULT 0 NOT NULL,
  "status_message" text,
  "last_downloaded" timestamp,
  PRIMARY KEY ("mirror_origin_id")
);
CREATE INDEX "mirror_origin_idx_site_id" on "mirror_origin" ("site_id");

;
--
-- Table: monthly_archive
--
CREATE TABLE "monthly_archive" (
  "monthly_archive_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "month" smallint NOT NULL,
  "year" smallint NOT NULL,
  PRIMARY KEY ("monthly_archive_id"),
  CONSTRAINT "site_id_month_year_unique" UNIQUE ("site_id", "month", "year")
);
CREATE INDEX "monthly_archive_idx_site_id" on "monthly_archive" ("site_id");

;
--
-- Table: node
--
CREATE TABLE "node" (
  "node_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "canonical_title" character varying(255) DEFAULT '' NOT NULL,
  "last_updated_epoch" integer DEFAULT 0 NOT NULL,
  "last_updated_dt" timestamp,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "full_path" text,
  "parent_node_id" integer,
  PRIMARY KEY ("node_id"),
  CONSTRAINT "site_id_uri_unique" UNIQUE ("site_id", "uri")
);
CREATE INDEX "node_idx_parent_node_id" on "node" ("parent_node_id");
CREATE INDEX "node_idx_site_id" on "node" ("site_id");

;
--
-- Table: oai_pmh_set
--
CREATE TABLE "oai_pmh_set" (
  "oai_pmh_set_id" serial NOT NULL,
  "set_spec" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "set_name" text,
  PRIMARY KEY ("oai_pmh_set_id"),
  CONSTRAINT "set_spec_site_id_unique" UNIQUE ("set_spec", "site_id")
);
CREATE INDEX "oai_pmh_set_idx_site_id" on "oai_pmh_set" ("site_id");

;
--
-- Table: redirection
--
CREATE TABLE "redirection" (
  "id" serial NOT NULL,
  "uri" character varying(255) NOT NULL,
  "type" character varying(16) NOT NULL,
  "redirect" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_type_site_id_unique" UNIQUE ("uri", "type", "site_id")
);
CREATE INDEX "redirection_idx_site_id" on "redirection" ("site_id");

;
--
-- Table: site_category_type
--
CREATE TABLE "site_category_type" (
  "site_id" character varying(16) NOT NULL,
  "category_type" character varying(16) NOT NULL,
  "active" smallint DEFAULT 1 NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "name_singular" character varying(255) NOT NULL,
  "name_plural" character varying(255) NOT NULL,
  "generate_index" smallint DEFAULT 1 NOT NULL,
  "in_colophon" smallint DEFAULT 0 NOT NULL,
  "xapian_custom_slot" smallint,
  "description" text,
  PRIMARY KEY ("site_id", "category_type")
);
CREATE INDEX "site_category_type_idx_site_id" on "site_category_type" ("site_id");

;
--
-- Table: site_link
--
CREATE TABLE "site_link" (
  "url" character varying(255) NOT NULL,
  "label" character varying(255) NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "menu" character varying(32) DEFAULT 'specials' NOT NULL,
  "site_id" character varying(16) NOT NULL
);
CREATE INDEX "site_link_idx_site_id" on "site_link" ("site_id");

;
--
-- Table: site_options
--
CREATE TABLE "site_options" (
  "site_id" character varying(16) NOT NULL,
  "option_name" character varying(64) NOT NULL,
  "option_value" text,
  PRIMARY KEY ("site_id", "option_name")
);
CREATE INDEX "site_options_idx_site_id" on "site_options" ("site_id");

;
--
-- Table: title
--
CREATE TABLE "title" (
  "id" serial NOT NULL,
  "title" text,
  "subtitle" text,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "date" text,
  "notes" text,
  "source" text,
  "list_title" text,
  "author" text,
  "uid" character varying(255) DEFAULT '' NOT NULL,
  "attach" text,
  "pubdate" timestamp NOT NULL,
  "status" character varying(16) DEFAULT 'unpublished' NOT NULL,
  "parent" character varying(255),
  "publisher" text,
  "isbn" text,
  "rights" text,
  "seriesname" text,
  "seriesnumber" text,
  "f_path" text NOT NULL,
  "f_name" character varying(255) NOT NULL,
  "f_archive_rel_path" character varying(32) NOT NULL,
  "f_timestamp" timestamp NOT NULL,
  "f_timestamp_epoch" integer DEFAULT 0 NOT NULL,
  "f_full_path_name" text NOT NULL,
  "f_suffix" character varying(16) NOT NULL,
  "f_class" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "deleted" text,
  "slides" smallint DEFAULT 0 NOT NULL,
  "text_structure" text,
  "cover" character varying(255) DEFAULT '' NOT NULL,
  "teaser" text,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "sku" character varying(64) DEFAULT '' NOT NULL,
  "text_qualification" character varying(32),
  "text_size" integer DEFAULT 0 NOT NULL,
  "attachment_index" integer DEFAULT 0 NOT NULL,
  "blob_container" smallint DEFAULT 0 NOT NULL,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_f_class_site_id_unique" UNIQUE ("uri", "f_class", "site_id")
);
CREATE INDEX "title_idx_site_id" on "title" ("site_id");

;
--
-- Table: vhost
--
CREATE TABLE "vhost" (
  "name" character varying(255) NOT NULL,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("name")
);
CREATE INDEX "vhost_idx_site_id" on "vhost" ("site_id");

;
--
-- Table: whitelist_ip
--
CREATE TABLE "whitelist_ip" (
  "site_id" character varying(16) NOT NULL,
  "ip" character varying(64) NOT NULL,
  "user_editable" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("site_id", "ip")
);
CREATE INDEX "whitelist_ip_idx_site_id" on "whitelist_ip" ("site_id");

;
--
-- Table: category_description
--
CREATE TABLE "category_description" (
  "category_description_id" serial NOT NULL,
  "muse_body" text,
  "html_body" text,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "last_modified_by" character varying(255),
  "category_id" integer NOT NULL,
  PRIMARY KEY ("category_description_id"),
  CONSTRAINT "category_id_lang_unique" UNIQUE ("category_id", "lang")
);
CREATE INDEX "category_description_idx_category_id" on "category_description" ("category_id");

;
--
-- Table: global_site_files
--
CREATE TABLE "global_site_files" (
  "site_id" character varying(16) NOT NULL,
  "attachment_id" integer,
  "file_name" character varying(255) NOT NULL,
  "file_type" character varying(255) NOT NULL,
  "file_path" text NOT NULL,
  "image_width" integer,
  "image_height" integer,
  PRIMARY KEY ("site_id", "file_name", "file_type")
);
CREATE INDEX "global_site_files_idx_attachment_id" on "global_site_files" ("attachment_id");
CREATE INDEX "global_site_files_idx_site_id" on "global_site_files" ("site_id");

;
--
-- Table: included_file
--
CREATE TABLE "included_file" (
  "included_file_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer NOT NULL,
  "file_path" text NOT NULL,
  "file_timestamp" timestamp,
  "file_epoch" integer,
  PRIMARY KEY ("included_file_id")
);
CREATE INDEX "included_file_idx_site_id" on "included_file" ("site_id");
CREATE INDEX "included_file_idx_title_id" on "included_file" ("title_id");

;
--
-- Table: job
--
CREATE TABLE "job" (
  "id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "bulk_job_id" integer,
  "task" character varying(32),
  "payload" text,
  "status" character varying(32),
  "created" timestamp NOT NULL,
  "started" timestamp,
  "completed" timestamp,
  "priority" integer DEFAULT 10 NOT NULL,
  "produced" character varying(255),
  "username" character varying(255),
  "errors" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "job_idx_bulk_job_id" on "job" ("bulk_job_id");
CREATE INDEX "job_idx_site_id" on "job" ("site_id");
CREATE INDEX "job_status_index" on "job" ("status");

;
--
-- Table: muse_header
--
CREATE TABLE "muse_header" (
  "title_id" integer NOT NULL,
  "muse_header" character varying(255) NOT NULL,
  "muse_value" text,
  "muse_value_html" text,
  PRIMARY KEY ("title_id", "muse_header")
);
CREATE INDEX "muse_header_idx_title_id" on "muse_header" ("title_id");

;
--
-- Table: node_body
--
CREATE TABLE "node_body" (
  "node_id" integer NOT NULL,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "title_muse" text,
  "title_html" text,
  "body_muse" text,
  "body_html" text,
  PRIMARY KEY ("node_id", "lang")
);
CREATE INDEX "node_body_idx_node_id" on "node_body" ("node_id");

;
--
-- Table: revision
--
CREATE TABLE "revision" (
  "id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer NOT NULL,
  "f_full_path_name" text,
  "message" text,
  "status" character varying(16) DEFAULT 'editing' NOT NULL,
  "session_id" character varying(255),
  "username" character varying(255),
  "updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "revision_idx_site_id" on "revision" ("site_id");
CREATE INDEX "revision_idx_title_id" on "revision" ("title_id");

;
--
-- Table: text_internal_link
--
CREATE TABLE "text_internal_link" (
  "title_id" integer NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "f_class" character varying(255) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "full_link" text NOT NULL
);
CREATE INDEX "text_internal_link_idx_site_id" on "text_internal_link" ("site_id");
CREATE INDEX "text_internal_link_idx_title_id" on "text_internal_link" ("title_id");

;
--
-- Table: text_part
--
CREATE TABLE "text_part" (
  "title_id" integer NOT NULL,
  "part_index" character varying(16) NOT NULL,
  "part_level" integer NOT NULL,
  "part_title" text NOT NULL,
  "part_size" integer NOT NULL,
  "toc_index" integer NOT NULL,
  "part_order" integer NOT NULL,
  PRIMARY KEY ("title_id", "part_index")
);
CREATE INDEX "text_part_idx_title_id" on "text_part" ("title_id");

;
--
-- Table: title_stat
--
CREATE TABLE "title_stat" (
  "title_stat_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer NOT NULL,
  "accessed" timestamp NOT NULL,
  "user_agent" text,
  "type" text,
  PRIMARY KEY ("title_stat_id")
);
CREATE INDEX "title_stat_idx_site_id" on "title_stat" ("site_id");
CREATE INDEX "title_stat_idx_title_id" on "title_stat" ("title_id");

;
--
-- Table: user_role
--
CREATE TABLE "user_role" (
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "role_id")
);
CREATE INDEX "user_role_idx_role_id" on "user_role" ("role_id");
CREATE INDEX "user_role_idx_user_id" on "user_role" ("user_id");

;
--
-- Table: user_site
--
CREATE TABLE "user_site" (
  "user_id" integer NOT NULL,
  "site_id" character varying(16) NOT NULL,
  PRIMARY KEY ("user_id", "site_id")
);
CREATE INDEX "user_site_idx_site_id" on "user_site" ("site_id");
CREATE INDEX "user_site_idx_user_id" on "user_site" ("user_id");

;
--
-- Table: job_file
--
CREATE TABLE "job_file" (
  "filename" character varying(255) NOT NULL,
  "slot" character varying(255) DEFAULT '' NOT NULL,
  "job_id" integer NOT NULL,
  PRIMARY KEY ("filename")
);
CREATE INDEX "job_file_idx_job_id" on "job_file" ("job_id");

;
--
-- Table: node_category
--
CREATE TABLE "node_category" (
  "node_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "category_id")
);
CREATE INDEX "node_category_idx_category_id" on "node_category" ("category_id");
CREATE INDEX "node_category_idx_node_id" on "node_category" ("node_id");

;
--
-- Table: node_title
--
CREATE TABLE "node_title" (
  "node_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "title_id")
);
CREATE INDEX "node_title_idx_node_id" on "node_title" ("node_id");
CREATE INDEX "node_title_idx_title_id" on "node_title" ("title_id");

;
--
-- Table: text_month
--
CREATE TABLE "text_month" (
  "title_id" integer NOT NULL,
  "monthly_archive_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "monthly_archive_id")
);
CREATE INDEX "text_month_idx_monthly_archive_id" on "text_month" ("monthly_archive_id");
CREATE INDEX "text_month_idx_title_id" on "text_month" ("title_id");

;
--
-- Table: title_attachment
--
CREATE TABLE "title_attachment" (
  "title_id" integer NOT NULL,
  "attachment_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "attachment_id")
);
CREATE INDEX "title_attachment_idx_attachment_id" on "title_attachment" ("attachment_id");
CREATE INDEX "title_attachment_idx_title_id" on "title_attachment" ("title_id");

;
--
-- Table: title_category
--
CREATE TABLE "title_category" (
  "title_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "category_id")
);
CREATE INDEX "title_category_idx_category_id" on "title_category" ("category_id");
CREATE INDEX "title_category_idx_title_id" on "title_category" ("title_id");

;
--
-- Table: mirror_info
--
CREATE TABLE "mirror_info" (
  "mirror_info_id" serial NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "mirror_origin_id" integer,
  "site_id" character varying(16) NOT NULL,
  "checksum" character varying(128),
  "download_source" text,
  "download_destination" text,
  "mirror_exception" character varying(32) DEFAULT '' NOT NULL,
  "last_updated" timestamp,
  PRIMARY KEY ("mirror_info_id"),
  CONSTRAINT "attachment_id_unique" UNIQUE ("attachment_id"),
  CONSTRAINT "title_id_unique" UNIQUE ("title_id")
);
CREATE INDEX "mirror_info_idx_attachment_id" on "mirror_info" ("attachment_id");
CREATE INDEX "mirror_info_idx_mirror_origin_id" on "mirror_info" ("mirror_origin_id");
CREATE INDEX "mirror_info_idx_site_id" on "mirror_info" ("site_id");
CREATE INDEX "mirror_info_idx_title_id" on "mirror_info" ("title_id");

;
--
-- Table: oai_pmh_record
--
CREATE TABLE "oai_pmh_record" (
  "oai_pmh_record_id" serial NOT NULL,
  "identifier" character varying(255) NOT NULL,
  "datestamp" timestamp NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer,
  "attachment_id" integer,
  "custom_formats_id" integer,
  "metadata_type" character varying(32),
  "metadata_format" character varying(32),
  "deleted" smallint DEFAULT 0 NOT NULL,
  "update_run" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("oai_pmh_record_id"),
  CONSTRAINT "identifier_site_id_unique" UNIQUE ("identifier", "site_id")
);
CREATE INDEX "oai_pmh_record_idx_attachment_id" on "oai_pmh_record" ("attachment_id");
CREATE INDEX "oai_pmh_record_idx_custom_formats_id" on "oai_pmh_record" ("custom_formats_id");
CREATE INDEX "oai_pmh_record_idx_site_id" on "oai_pmh_record" ("site_id");
CREATE INDEX "oai_pmh_record_idx_title_id" on "oai_pmh_record" ("title_id");

;
--
-- Table: oai_pmh_record_set
--
CREATE TABLE "oai_pmh_record_set" (
  "oai_pmh_record_id" integer NOT NULL,
  "oai_pmh_set_id" integer NOT NULL,
  PRIMARY KEY ("oai_pmh_record_id", "oai_pmh_set_id")
);
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_record_id" on "oai_pmh_record_set" ("oai_pmh_record_id");
CREATE INDEX "oai_pmh_record_set_idx_oai_pmh_set_id" on "oai_pmh_record_set" ("oai_pmh_set_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "amw_session" ADD CONSTRAINT "amw_session_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "attachment" ADD CONSTRAINT "attachment_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bookbuilder_profile" ADD CONSTRAINT "bookbuilder_profile_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bookbuilder_session" ADD CONSTRAINT "bookbuilder_session_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "bulk_job" ADD CONSTRAINT "bulk_job_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "category" ADD CONSTRAINT "category_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "custom_formats" ADD CONSTRAINT "custom_formats_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "include_path" ADD CONSTRAINT "include_path_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "legacy_link" ADD CONSTRAINT "legacy_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_origin" ADD CONSTRAINT "mirror_origin_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "monthly_archive" ADD CONSTRAINT "monthly_archive_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node" ADD CONSTRAINT "node_fk_parent_node_id" FOREIGN KEY ("parent_node_id")
  REFERENCES "node" ("node_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "node" ADD CONSTRAINT "node_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_set" ADD CONSTRAINT "oai_pmh_set_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "redirection" ADD CONSTRAINT "redirection_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "site_category_type" ADD CONSTRAINT "site_category_type_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "site_link" ADD CONSTRAINT "site_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "site_options" ADD CONSTRAINT "site_options_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title" ADD CONSTRAINT "title_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "vhost" ADD CONSTRAINT "vhost_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "whitelist_ip" ADD CONSTRAINT "whitelist_ip_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "category_description" ADD CONSTRAINT "category_description_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "global_site_files" ADD CONSTRAINT "global_site_files_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "global_site_files" ADD CONSTRAINT "global_site_files_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "included_file" ADD CONSTRAINT "included_file_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "included_file" ADD CONSTRAINT "included_file_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "job" ADD CONSTRAINT "job_fk_bulk_job_id" FOREIGN KEY ("bulk_job_id")
  REFERENCES "bulk_job" ("bulk_job_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "job" ADD CONSTRAINT "job_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "muse_header" ADD CONSTRAINT "muse_header_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_body" ADD CONSTRAINT "node_body_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "revision" ADD CONSTRAINT "revision_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "revision" ADD CONSTRAINT "revision_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_internal_link" ADD CONSTRAINT "text_internal_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_internal_link" ADD CONSTRAINT "text_internal_link_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_part" ADD CONSTRAINT "text_part_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_stat" ADD CONSTRAINT "title_stat_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_stat" ADD CONSTRAINT "title_stat_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "roles" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "job_file" ADD CONSTRAINT "job_file_fk_job_id" FOREIGN KEY ("job_id")
  REFERENCES "job" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_category" ADD CONSTRAINT "node_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_category" ADD CONSTRAINT "node_category_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_title" ADD CONSTRAINT "node_title_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_title" ADD CONSTRAINT "node_title_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_month" ADD CONSTRAINT "text_month_fk_monthly_archive_id" FOREIGN KEY ("monthly_archive_id")
  REFERENCES "monthly_archive" ("monthly_archive_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_month" ADD CONSTRAINT "text_month_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_attachment" ADD CONSTRAINT "title_attachment_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_attachment" ADD CONSTRAINT "title_attachment_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_category" ADD CONSTRAINT "title_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_category" ADD CONSTRAINT "title_category_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_mirror_origin_id" FOREIGN KEY ("mirror_origin_id")
  REFERENCES "mirror_origin" ("mirror_origin_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "mirror_info" ADD CONSTRAINT "mirror_info_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_custom_formats_id" FOREIGN KEY ("custom_formats_id")
  REFERENCES "custom_formats" ("custom_formats_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record" ADD CONSTRAINT "oai_pmh_record_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record_set" ADD CONSTRAINT "oai_pmh_record_set_fk_oai_pmh_record_id" FOREIGN KEY ("oai_pmh_record_id")
  REFERENCES "oai_pmh_record" ("oai_pmh_record_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "oai_pmh_record_set" ADD CONSTRAINT "oai_pmh_record_set_fk_oai_pmh_set_id" FOREIGN KEY ("oai_pmh_set_id")
  REFERENCES "oai_pmh_set" ("oai_pmh_set_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
