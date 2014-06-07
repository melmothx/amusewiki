-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sat Jun  7 12:55:09 2014
-- 
--
-- Table: role.
--
DROP TABLE "role" CASCADE;
CREATE TABLE "role" (
  "id" serial NOT NULL,
  "role" character varying(128),
  PRIMARY KEY ("id"),
  CONSTRAINT "role_unique" UNIQUE ("role")
);

--
-- Table: site.
--
DROP TABLE "site" CASCADE;
CREATE TABLE "site" (
  "id" character varying(8) NOT NULL,
  "mode" character varying(16) DEFAULT 'blog' NOT NULL,
  "locale" character varying(3) DEFAULT 'en' NOT NULL,
  "magic_question" text DEFAULT '' NOT NULL,
  "magic_answer" text DEFAULT '' NOT NULL,
  "fixed_category_list" text,
  "sitename" character varying(255) DEFAULT '' NOT NULL,
  "siteslogan" character varying(255) DEFAULT '' NOT NULL,
  "theme" character varying(32) DEFAULT '' NOT NULL,
  "logo" character varying(32),
  "mail" character varying(128),
  "canonical" character varying(255) DEFAULT '' NOT NULL,
  "sitegroup" character varying(32),
  "bb_page_limit" integer DEFAULT 1000 NOT NULL,
  "tex" integer DEFAULT 1 NOT NULL,
  "pdf" integer DEFAULT 1 NOT NULL,
  "a4_pdf" integer DEFAULT 1 NOT NULL,
  "lt_pdf" integer DEFAULT 1 NOT NULL,
  "html" integer DEFAULT 1 NOT NULL,
  "bare_html" integer DEFAULT 1 NOT NULL,
  "epub" integer DEFAULT 1 NOT NULL,
  "zip" integer DEFAULT 1 NOT NULL,
  "ttdir" character varying(1024) DEFAULT '' NOT NULL,
  "papersize" character varying(64) DEFAULT '' NOT NULL,
  "division" integer DEFAULT 12 NOT NULL,
  "bcor" character varying(16) DEFAULT '0mm' NOT NULL,
  "fontsize" integer DEFAULT 10 NOT NULL,
  "mainfont" character varying(255) DEFAULT 'Linux Libertine O' NOT NULL,
  "twoside" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: user.
--
DROP TABLE "user" CASCADE;
CREATE TABLE "user" (
  "id" serial NOT NULL,
  "username" character varying(128) NOT NULL,
  "password" character varying(255) NOT NULL,
  "email" character varying(255),
  "active" integer DEFAULT 1 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "username_unique" UNIQUE ("username")
);

--
-- Table: attachment.
--
DROP TABLE "attachment" CASCADE;
CREATE TABLE "attachment" (
  "id" serial NOT NULL,
  "f_path" text NOT NULL,
  "f_name" character varying(255) NOT NULL,
  "f_archive_rel_path" character varying(4) NOT NULL,
  "f_timestamp" timestamp NOT NULL,
  "f_timestamp_epoch" integer DEFAULT 0 NOT NULL,
  "f_full_path_name" text NOT NULL,
  "f_suffix" character varying(16) NOT NULL,
  "f_class" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_site_id_unique" UNIQUE ("uri", "site_id")
);
CREATE INDEX "attachment_idx_site_id" on "attachment" ("site_id");

--
-- Table: category.
--
DROP TABLE "category" CASCADE;
CREATE TABLE "category" (
  "id" serial NOT NULL,
  "name" text,
  "uri" character varying(255) NOT NULL,
  "type" character varying(16) NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "text_count" integer DEFAULT 0 NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_site_id_type_unique" UNIQUE ("uri", "site_id", "type")
);
CREATE INDEX "category_idx_site_id" on "category" ("site_id");

--
-- Table: job.
--
DROP TABLE "job" CASCADE;
CREATE TABLE "job" (
  "id" serial NOT NULL,
  "site_id" character varying(8) NOT NULL,
  "task" character varying(32),
  "payload" text,
  "status" character varying(32),
  "created" timestamp NOT NULL,
  "completed" timestamp,
  "priority" integer,
  "produced" character varying(255),
  "errors" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "job_idx_site_id" on "job" ("site_id");

--
-- Table: title.
--
DROP TABLE "title" CASCADE;
CREATE TABLE "title" (
  "id" serial NOT NULL,
  "title" text DEFAULT '' NOT NULL,
  "subtitle" text DEFAULT '' NOT NULL,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "date" text DEFAULT '' NOT NULL,
  "notes" text DEFAULT '' NOT NULL,
  "source" text DEFAULT '' NOT NULL,
  "list_title" text DEFAULT '' NOT NULL,
  "author" text DEFAULT '' NOT NULL,
  "uid" character varying(255),
  "attach" character varying(255),
  "pubdate" timestamp NOT NULL,
  "status" character varying(16) DEFAULT 'unpublished' NOT NULL,
  "f_path" text NOT NULL,
  "f_name" character varying(255) NOT NULL,
  "f_archive_rel_path" character varying(4) NOT NULL,
  "f_timestamp" timestamp NOT NULL,
  "f_timestamp_epoch" integer DEFAULT 0 NOT NULL,
  "f_full_path_name" text NOT NULL,
  "f_suffix" character varying(16) NOT NULL,
  "f_class" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "deleted" text DEFAULT '' NOT NULL,
  "sorting_pos" integer DEFAULT 0 NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "uri_f_class_site_id_unique" UNIQUE ("uri", "f_class", "site_id")
);
CREATE INDEX "title_idx_site_id" on "title" ("site_id");

--
-- Table: vhost.
--
DROP TABLE "vhost" CASCADE;
CREATE TABLE "vhost" (
  "name" character varying(255) NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("name")
);
CREATE INDEX "vhost_idx_site_id" on "vhost" ("site_id");

--
-- Table: revision.
--
DROP TABLE "revision" CASCADE;
CREATE TABLE "revision" (
  "id" serial NOT NULL,
  "site_id" character varying(8) NOT NULL,
  "title_id" integer NOT NULL,
  "f_full_path_name" text,
  "message" text,
  "status" character varying(16) DEFAULT 'editing' NOT NULL,
  "session_id" character varying(255),
  "updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "revision_idx_site_id" on "revision" ("site_id");
CREATE INDEX "revision_idx_title_id" on "revision" ("title_id");

--
-- Table: user_role.
--
DROP TABLE "user_role" CASCADE;
CREATE TABLE "user_role" (
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "role_id")
);
CREATE INDEX "user_role_idx_role_id" on "user_role" ("role_id");
CREATE INDEX "user_role_idx_user_id" on "user_role" ("user_id");

--
-- Table: user_site.
--
DROP TABLE "user_site" CASCADE;
CREATE TABLE "user_site" (
  "user_id" integer NOT NULL,
  "site_id" character varying(8) NOT NULL,
  PRIMARY KEY ("user_id", "site_id")
);
CREATE INDEX "user_site_idx_site_id" on "user_site" ("site_id");
CREATE INDEX "user_site_idx_user_id" on "user_site" ("user_id");

--
-- Table: title_category.
--
DROP TABLE "title_category" CASCADE;
CREATE TABLE "title_category" (
  "title_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "category_id")
);
CREATE INDEX "title_category_idx_category_id" on "title_category" ("category_id");
CREATE INDEX "title_category_idx_title_id" on "title_category" ("title_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "attachment" ADD CONSTRAINT "attachment_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "category" ADD CONSTRAINT "category_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "job" ADD CONSTRAINT "job_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "title" ADD CONSTRAINT "title_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "vhost" ADD CONSTRAINT "vhost_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "revision" ADD CONSTRAINT "revision_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "revision" ADD CONSTRAINT "revision_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "role" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_site" ADD CONSTRAINT "user_site_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "title_category" ADD CONSTRAINT "title_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "title_category" ADD CONSTRAINT "title_category_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

