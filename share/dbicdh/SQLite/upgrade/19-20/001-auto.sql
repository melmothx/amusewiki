-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/19/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN blog_style integer(1) NOT NULL DEFAULT 0;

;

COMMIT;

