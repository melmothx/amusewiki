-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/50/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/51/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "tag" (
  "tag_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "uri" varchar(255) NOT NULL,
  "parent_tag_id" integer,
  FOREIGN KEY ("parent_tag_id") REFERENCES "tag"("tag_id") ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "tag_idx_parent_tag_id" ON "tag" ("parent_tag_id");

;
CREATE INDEX "tag_idx_site_id" ON "tag" ("site_id");

;
CREATE UNIQUE INDEX "site_id_uri_unique" ON "tag" ("site_id", "uri");

;
CREATE TABLE "tag_body" (
  "tag_id" integer NOT NULL,
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "title_muse" text,
  "title_html" text,
  "body_muse" text,
  "body_html" text,
  PRIMARY KEY ("tag_id", "lang"),
  FOREIGN KEY ("tag_id") REFERENCES "tag"("tag_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "tag_body_idx_tag_id" ON "tag_body" ("tag_id");

;
CREATE TABLE "tag_category" (
  "tag_id" integer NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("tag_id", "category_id"),
  FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("tag_id") REFERENCES "tag"("tag_id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "tag_category_idx_category_id" ON "tag_category" ("category_id");

;
CREATE INDEX "tag_category_idx_tag_id" ON "tag_category" ("tag_id");

;
CREATE TABLE "tag_title" (
  "tag_id" integer NOT NULL,
  "title_id" integer NOT NULL,
  PRIMARY KEY ("tag_id", "title_id"),
  FOREIGN KEY ("tag_id") REFERENCES "tag"("tag_id") ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ("title_id") REFERENCES "title"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "tag_title_idx_tag_id" ON "tag_title" ("tag_id");

;
CREATE INDEX "tag_title_idx_title_id" ON "tag_title" ("title_id");

;

COMMIT;

