-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/73/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/74/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "site_category_type" ADD COLUMN "in_colophon" smallint DEFAULT 0 NOT NULL;

;

COMMIT;

