-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/39/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE custom_formats ADD COLUMN format_alias character varying(8);

;
ALTER TABLE custom_formats ADD COLUMN format_priority integer DEFAULT 0 NOT NULL;

;
ALTER TABLE custom_formats ADD COLUMN bb_coverpage_only_if_toc smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_impressum smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_sansfontsections smallint DEFAULT 0;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_2up character varying(8) DEFAULT '40-80' NOT NULL;

;
ALTER TABLE custom_formats ADD COLUMN bb_signature_4up character varying(8) DEFAULT '40-80' NOT NULL;

;
ALTER TABLE custom_formats ADD CONSTRAINT site_id_format_alias_unique UNIQUE (site_id, format_alias);

;
ALTER TABLE job ADD COLUMN started timestamp;

;

COMMIT;

