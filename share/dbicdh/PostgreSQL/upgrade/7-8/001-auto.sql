-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/7/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN secure_site_only smallint DEFAULT 0 NOT NULL;

;

COMMIT;

