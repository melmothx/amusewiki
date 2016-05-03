-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/15/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN reset_token text;

;
ALTER TABLE users ADD COLUMN reset_until integer;

;

COMMIT;

