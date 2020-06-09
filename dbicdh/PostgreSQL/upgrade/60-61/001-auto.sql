-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/60/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/61/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "whitelist_ip" ADD COLUMN "user_editable" smallint DEFAULT 0 NOT NULL;

;

COMMIT;

