-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/35/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
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
ALTER TABLE "text_internal_link" ADD CONSTRAINT "text_internal_link_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_internal_link" ADD CONSTRAINT "text_internal_link_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

