-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE attachment ADD COLUMN title_muse text;

;
ALTER TABLE attachment ADD COLUMN comment_muse text;

;
ALTER TABLE attachment ADD COLUMN title_html text;

;
ALTER TABLE attachment ADD COLUMN comment_html text;

;

COMMIT;

