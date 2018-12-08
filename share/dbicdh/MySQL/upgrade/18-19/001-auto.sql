-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/18/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title ADD COLUMN cover varchar(255) NOT NULL DEFAULT '',
                  ADD COLUMN teaser text NOT NULL DEFAULT '';

;

COMMIT;

