-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "node" (
  "node_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "uri" character varying(255) NOT NULL,
  "parent_node_id" integer,
  PRIMARY KEY ("node_id"),
  CONSTRAINT "site_id_uri_unique" UNIQUE ("site_id", "uri")
);
CREATE INDEX "node_idx_parent_node_id" on "node" ("parent_node_id");
CREATE INDEX "node_idx_site_id" on "node" ("site_id");

;
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
CREATE TABLE "node_category" (
  "node_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "category_id")
);
CREATE INDEX "node_category_idx_category_id" on "node_category" ("category_id");
CREATE INDEX "node_category_idx_node_id" on "node_category" ("node_id");

;
CREATE TABLE "node_title" (
  "node_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  PRIMARY KEY ("node_id", "title_id")
);
CREATE INDEX "node_title_idx_node_id" on "node_title" ("node_id");
CREATE INDEX "node_title_idx_title_id" on "node_title" ("title_id");

;
ALTER TABLE "node" ADD CONSTRAINT "node_fk_parent_node_id" FOREIGN KEY ("parent_node_id")
  REFERENCES "node" ("node_id") ON DELETE SET NULL ON UPDATE CASCADE;

;
ALTER TABLE "node" ADD CONSTRAINT "node_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "node_body" ADD CONSTRAINT "node_body_fk_node_id" FOREIGN KEY ("node_id")
  REFERENCES "node" ("node_id") ON DELETE CASCADE ON UPDATE CASCADE;

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

COMMIT;

