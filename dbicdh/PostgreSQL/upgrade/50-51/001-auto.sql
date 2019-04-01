-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "tag" (
  "tag_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "parent_tag_id" integer,
  PRIMARY KEY ("tag_id"),
  CONSTRAINT "site_id_uri_unique" UNIQUE ("site_id", "uri")
);
CREATE INDEX "tag_idx_parent_tag_id" on "tag" ("parent_tag_id");
CREATE INDEX "tag_idx_site_id" on "tag" ("site_id");

;
CREATE TABLE "tag_body" (
  "tag_id" integer NOT NULL,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "title_muse" text,
  "title_html" text,
  "body_muse" text,
  "body_html" text,
  PRIMARY KEY ("tag_id", "lang")
);
CREATE INDEX "tag_body_idx_tag_id" on "tag_body" ("tag_id");

;
CREATE TABLE "tag_category" (
  "tag_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("tag_id", "category_id")
);
CREATE INDEX "tag_category_idx_category_id" on "tag_category" ("category_id");
CREATE INDEX "tag_category_idx_tag_id" on "tag_category" ("tag_id");

;
CREATE TABLE "tag_title" (
  "tag_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  PRIMARY KEY ("tag_id", "title_id")
);
CREATE INDEX "tag_title_idx_tag_id" on "tag_title" ("tag_id");
CREATE INDEX "tag_title_idx_title_id" on "tag_title" ("title_id");

;
ALTER TABLE "tag" ADD CONSTRAINT "tag_fk_parent_tag_id" FOREIGN KEY ("parent_tag_id")
  REFERENCES "tag" ("tag_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "tag" ADD CONSTRAINT "tag_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "tag_body" ADD CONSTRAINT "tag_body_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tag" ("tag_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "tag_category" ADD CONSTRAINT "tag_category_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "tag_category" ADD CONSTRAINT "tag_category_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tag" ("tag_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "tag_title" ADD CONSTRAINT "tag_title_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tag" ("tag_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "tag_title" ADD CONSTRAINT "tag_title_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

