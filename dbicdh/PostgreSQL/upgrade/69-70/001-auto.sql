-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/69/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/70/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "custom_formats" ADD COLUMN "bb_parindent" integer DEFAULT 15 NOT NULL;

;

COMMIT;

