-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/7/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN secure_site_only integer(1) NOT NULL DEFAULT 0;

;

COMMIT;

