-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/53/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/54/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE attachment ADD COLUMN mime_type character varying(255);

;
ALTER TABLE site ADD COLUMN binary_upload_max_size_in_mega integer DEFAULT 8 NOT NULL;

;
ALTER TABLE title ADD COLUMN blob_container smallint DEFAULT 0 NOT NULL;

;

COMMIT;

