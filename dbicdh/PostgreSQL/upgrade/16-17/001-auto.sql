-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/16/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "title_stat" (
  "title_stat_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title_id" integer NOT NULL,
  "accessed" timestamp NOT NULL,
  "notes" text,
  PRIMARY KEY ("title_stat_id")
);
CREATE INDEX "title_stat_idx_site_id" on "title_stat" ("site_id");
CREATE INDEX "title_stat_idx_title_id" on "title_stat" ("title_id");

;
ALTER TABLE "title_stat" ADD CONSTRAINT "title_stat_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "title_stat" ADD CONSTRAINT "title_stat_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

