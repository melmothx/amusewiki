-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/55/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/56/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "site_category_type" (
  "site_id" character varying(16) NOT NULL,
  "category_type" character varying(16) NOT NULL,
  "active" smallint DEFAULT 1 NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "name_singular" character varying(255) NOT NULL,
  "name_plural" character varying(255) NOT NULL,
  PRIMARY KEY ("site_id", "category_type")
);
CREATE INDEX "site_category_type_idx_site_id" on "site_category_type" ("site_id");

;
ALTER TABLE "site_category_type" ADD CONSTRAINT "site_category_type_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

