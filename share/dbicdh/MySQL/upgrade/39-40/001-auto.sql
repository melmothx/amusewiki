-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/39/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_alias varchar(8) NULL,
                           ADD COLUMN format_priority integer NOT NULL DEFAULT 0,
                           ADD COLUMN bb_coverpage_only_if_toc smallint NULL DEFAULT 0,
                           ADD COLUMN bb_impressum smallint NULL DEFAULT 0,
                           ADD COLUMN bb_sansfontsections smallint NULL DEFAULT 0,
                           ADD COLUMN bb_signature_2up varchar(8) NOT NULL DEFAULT '40-80',
                           ADD COLUMN bb_signature_4up varchar(8) NOT NULL DEFAULT '40-80',
                           ADD UNIQUE site_id_format_alias_unique (site_id, format_alias);

;
ALTER TABLE job ADD COLUMN started datetime NULL;

;

COMMIT;

