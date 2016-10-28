-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/26/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN edit_option_preview_box_height integer NOT NULL DEFAULT 500,
                  ADD COLUMN edit_option_show_filters integer(1) NOT NULL DEFAULT 1,
                  ADD COLUMN edit_option_show_cheatsheet integer(1) NOT NULL DEFAULT 1,
                  ADD COLUMN edit_option_page_left_bs_columns integer NULL DEFAULT 6;

;

COMMIT;

