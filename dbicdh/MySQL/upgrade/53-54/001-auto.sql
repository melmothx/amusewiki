-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/53/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/54/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE attachment ADD COLUMN mime_type varchar(255) NULL;

;
ALTER TABLE site ADD COLUMN binary_upload_max_size_in_mega integer NOT NULL DEFAULT 8;

;
ALTER TABLE title ADD COLUMN blob_container integer(1) NOT NULL DEFAULT 0;

;

COMMIT;

