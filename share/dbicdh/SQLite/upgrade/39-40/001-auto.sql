-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/39/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_alias varchar(8);

;
ALTER TABLE custom_formats ADD COLUMN format_priority integer NOT NULL DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_coverpage_only_if_toc smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_impressum smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_sansfontsections smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_2up varchar(8) NOT NULL DEFAULT '40-80';

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_4up varchar(8) NOT NULL DEFAULT '40-80';

;
CREATE UNIQUE INDEX site_id_format_alias_unique ON custom_formats (site_id, format_alias);

;
ALTER TABLE job ADD COLUMN started datetime;

;

COMMIT;

