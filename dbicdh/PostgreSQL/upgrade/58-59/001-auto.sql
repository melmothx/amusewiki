-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/58/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "site" ADD COLUMN "git_token" character varying(255);

;

COMMIT;

