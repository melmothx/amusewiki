-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/28/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE bulk_job ADD COLUMN status varchar(32);

;
CREATE INDEX job_status_index ON job (status);

;

COMMIT;

