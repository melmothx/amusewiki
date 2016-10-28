-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/26/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN edit_option_preview_box_heigth integer DEFAULT 500 NOT NULL;

;
ALTER TABLE users ADD COLUMN edit_option_show_filters smallint DEFAULT 1 NOT NULL;

;
ALTER TABLE users ADD COLUMN edit_option_show_cheatsheet smallint DEFAULT 1 NOT NULL;

;
ALTER TABLE users ADD COLUMN edit_option_page_left_bs_columns integer DEFAULT 6;

;

COMMIT;

