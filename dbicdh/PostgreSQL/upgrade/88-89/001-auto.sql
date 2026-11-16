-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/88/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/89/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "annotation" ADD COLUMN "oai_pmh_field" character varying(64);

;
ALTER TABLE "site_category_type" ADD COLUMN "oai_pmh_field" character varying(64);

;

COMMIT;

