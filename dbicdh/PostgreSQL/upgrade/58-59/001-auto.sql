-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/58/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "site" ADD COLUMN "git_token" text;

;
ALTER TABLE "site" ALTER COLUMN "fixed_category_list" TYPE text;

;
ALTER TABLE "site" ALTER COLUMN "mail_notify" TYPE text;

;
ALTER TABLE "site" ALTER COLUMN "mail_from" TYPE text;

;

COMMIT;

