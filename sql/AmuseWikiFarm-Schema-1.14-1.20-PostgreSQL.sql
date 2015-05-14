-- Convert schema 'sql/AmuseWikiFarm-Schema-1.14-PostgreSQL.sql' to 'sql/AmuseWikiFarm-Schema-1.20-PostgreSQL.sql':;

BEGIN;

CREATE TABLE "category_description" (
  "category_description_id" serial NOT NULL,
  "muse_body" text,
  "html_body" text,
  "lang" character varying(3) DEFAULT 'en' NOT NULL,
  "category_id" integer NOT NULL,
  PRIMARY KEY ("category_description_id"),
  CONSTRAINT "category_id_lang_unique" UNIQUE ("category_id", "lang")
);
CREATE INDEX "category_description_idx_category_id" on "category_description" ("category_id");

ALTER TABLE "category_description" ADD CONSTRAINT "category_description_fk_category_id" FOREIGN KEY ("category_id")
  REFERENCES "category" ("id") ON DELETE cascade ON UPDATE cascade DEFERRABLE;


COMMIT;

