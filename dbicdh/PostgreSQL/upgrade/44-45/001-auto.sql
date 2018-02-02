-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/44/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN attachment_index integer DEFAULT 0 NOT NULL;

;

COMMIT;

