-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/80/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/81/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "oai_pmh_record" ADD COLUMN "metadata_format_description" character varying(255);

;

COMMIT;

