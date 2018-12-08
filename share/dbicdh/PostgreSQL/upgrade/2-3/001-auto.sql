-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/2/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE category_description ADD COLUMN last_modified_by character varying(255);

;
ALTER TABLE site ADD COLUMN sl_pdf smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE site ADD COLUMN sansfont character varying(255) DEFAULT 'CMU Sans Serif' NOT NULL;

;
ALTER TABLE site ADD COLUMN monofont character varying(255) DEFAULT 'CMU Typewriter Text' NOT NULL;

;
ALTER TABLE site ADD COLUMN beamertheme character varying(255) DEFAULT 'default' NOT NULL;

;
ALTER TABLE site ADD COLUMN beamercolortheme character varying(255) DEFAULT 'dove' NOT NULL;

;
ALTER TABLE site ALTER COLUMN mainfont SET DEFAULT 'CMU Serif';

;
ALTER TABLE title ADD COLUMN slides smallint DEFAULT 0 NOT NULL;

;
ALTER TABLE users ADD COLUMN created_by character varying(255);

;

COMMIT;

