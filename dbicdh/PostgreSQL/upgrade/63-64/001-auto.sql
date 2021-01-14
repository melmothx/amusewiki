-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/63/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/64/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "title" ALTER COLUMN "text_qualification" TYPE character varying(32);

;

COMMIT;

