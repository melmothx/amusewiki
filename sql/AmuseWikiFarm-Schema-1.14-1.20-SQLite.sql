-- Convert schema 'sql/AmuseWikiFarm-Schema-1.14-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-1.20-SQLite.sql':;

BEGIN;

CREATE TABLE "category_description" (
  "category_description_id" INTEGER PRIMARY KEY NOT NULL,
  "muse_body" text,
  "html_body" text,
  "lang" varchar(3) NOT NULL DEFAULT 'en',
  "category_id" integer NOT NULL,
  FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "category_description_idx_category_id" ON "category_description" ("category_id");

CREATE UNIQUE INDEX "category_id_lang_unique" ON "category_description" ("category_id", "lang");


COMMIT;

