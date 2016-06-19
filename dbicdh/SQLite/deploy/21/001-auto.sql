-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Sun Jun 19 13:03:45 2016
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
  "fixed_category_list" varchar(255),
  "sitename" varchar(255) NOT NULL DEFAULT '',
  "siteslogan" varchar(255) NOT NULL DEFAULT '',
  "theme" varchar(32) NOT NULL DEFAULT '',
  "logo" varchar(255) NOT NULL DEFAULT '',
  "mail_notify" varchar(255),
  "mail_from" varchar(255),
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
  "reset_token" text,
  "reset_until" integer
);
CREATE UNIQUE INDEX "username_unique" ON "users" ("username");
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
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "attachment_idx_site_id" ON "attachment" ("site_id");
CREATE UNIQUE INDEX "uri_site_id_unique" ON "attachment" ("uri", "site_id");
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
  "site_id" varchar(16) NOT NULL,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "category_idx_site_id" ON "category" ("site_id");
CREATE UNIQUE INDEX "uri_site_id_type_unique" ON "category" ("uri", "site_id", "type");
--
-- Table: "job"
--
CREATE TABLE "job" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "task" varchar(32),
  "payload" text,
  "status" varchar(32),
  "created" datetime NOT NULL,
  "completed" datetime,
  "priority" integer,
  "produced" varchar(255),
  "username" varchar(255),
  "errors" text,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "job_idx_site_id" ON "job" ("site_id");
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
-- Table: "site_link"
--
CREATE TABLE "site_link" (
  "url" varchar(255) NOT NULL,
  "label" varchar(255) NOT NULL,
  "sorting_pos" integer NOT NULL DEFAULT 0,
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
  "title" text NOT NULL DEFAULT '',
  "subtitle" text NOT NULL DEFAULT '',
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "date" text NOT NULL DEFAULT '',
  "notes" text NOT NULL DEFAULT '',
  "source" text NOT NULL DEFAULT '',
  "list_title" text NOT NULL DEFAULT '',
  "author" text NOT NULL DEFAULT '',
  "uid" varchar(255) NOT NULL DEFAULT '',
  "attach" text,
  "pubdate" datetime NOT NULL,
  "status" varchar(16) NOT NULL DEFAULT 'unpublished',
  "f_path" text NOT NULL,
  "f_name" varchar(255) NOT NULL,
  "f_archive_rel_path" varchar(32) NOT NULL,
  "f_timestamp" datetime NOT NULL,
  "f_timestamp_epoch" integer NOT NULL DEFAULT 0,
  "f_full_path_name" text NOT NULL,
  "f_suffix" varchar(16) NOT NULL,
  "f_class" varchar(16) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "deleted" text NOT NULL DEFAULT '',
  "slides" integer(1) NOT NULL DEFAULT 0,
  "text_structure" text NOT NULL DEFAULT '',
  "cover" varchar(255) NOT NULL DEFAULT '',
  "teaser" text NOT NULL DEFAULT '',
  "sorting_pos" integer NOT NULL DEFAULT 0,
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
COMMIT;
