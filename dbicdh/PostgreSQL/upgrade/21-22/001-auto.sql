-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "monthly_archive" (
  "monthly_archive_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "month" smallint NOT NULL,
  "year" smallint NOT NULL,
  PRIMARY KEY ("monthly_archive_id"),
  CONSTRAINT "site_id_month_year_unique" UNIQUE ("site_id", "month", "year")
);
CREATE INDEX "monthly_archive_idx_site_id" on "monthly_archive" ("site_id");

;
CREATE TABLE "text_month" (
  "title_id" integer NOT NULL,
  "monthly_archive_id" integer NOT NULL,
  PRIMARY KEY ("title_id", "monthly_archive_id")
);
CREATE INDEX "text_month_idx_monthly_archive_id" on "text_month" ("monthly_archive_id");
CREATE INDEX "text_month_idx_title_id" on "text_month" ("title_id");

;
ALTER TABLE "monthly_archive" ADD CONSTRAINT "monthly_archive_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_month" ADD CONSTRAINT "text_month_fk_monthly_archive_id" FOREIGN KEY ("monthly_archive_id")
  REFERENCES "monthly_archive" ("monthly_archive_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "text_month" ADD CONSTRAINT "text_month_fk_title_id" FOREIGN KEY ("title_id")
  REFERENCES "title" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

