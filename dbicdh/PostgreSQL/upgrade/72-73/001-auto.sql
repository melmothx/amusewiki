-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/72/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/73/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "muse_header" ADD COLUMN "muse_value_html" text;

;
ALTER TABLE "site_category_type" ADD COLUMN "generate_index" smallint DEFAULT 1 NOT NULL;

;

COMMIT;

