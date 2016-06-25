-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/19/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN blog_style smallint DEFAULT 0 NOT NULL;

;

COMMIT;

