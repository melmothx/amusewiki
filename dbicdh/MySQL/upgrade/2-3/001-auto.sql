-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/2/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE category_description ADD COLUMN last_modified_by varchar(255) NULL;

;
ALTER TABLE site ADD COLUMN sl_pdf integer(1) NOT NULL DEFAULT 0,
                 ADD COLUMN sansfont varchar(255) NOT NULL DEFAULT 'CMU Sans Serif',
                 ADD COLUMN monofont varchar(255) NOT NULL DEFAULT 'CMU Typewriter Text',
                 ADD COLUMN beamertheme varchar(255) NOT NULL DEFAULT 'default',
                 ADD COLUMN beamercolortheme varchar(255) NOT NULL DEFAULT 'dove',
                 CHANGE COLUMN mainfont mainfont varchar(255) NOT NULL DEFAULT 'CMU Serif';

;
ALTER TABLE title ADD COLUMN slides integer(1) NOT NULL DEFAULT 0;

;
ALTER TABLE users ADD COLUMN created_by varchar(255) NULL;

;

COMMIT;

