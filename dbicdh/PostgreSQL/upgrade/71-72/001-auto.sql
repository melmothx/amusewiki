-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/71/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/72/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "custom_formats" ADD COLUMN "bb_body_only" smallint DEFAULT 0;

;

COMMIT;

