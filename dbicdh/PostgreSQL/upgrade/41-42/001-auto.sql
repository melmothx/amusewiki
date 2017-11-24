-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/41/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/42/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site_link ADD COLUMN menu character varying(32) DEFAULT 'specials' NOT NULL;

;

COMMIT;

