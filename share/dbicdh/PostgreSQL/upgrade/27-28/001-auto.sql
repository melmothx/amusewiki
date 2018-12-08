-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/27/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "bulk_job" (
  "bulk_job_id" serial NOT NULL,
  "task" character varying(32),
  "created" timestamp NOT NULL,
  "completed" timestamp,
  "site_id" character varying(16) NOT NULL,
  "username" character varying(255),
  PRIMARY KEY ("bulk_job_id")
);
CREATE INDEX "bulk_job_idx_site_id" on "bulk_job" ("site_id");

;
ALTER TABLE "bulk_job" ADD CONSTRAINT "bulk_job_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE job ADD COLUMN bulk_job_id integer;

;
ALTER TABLE job ALTER COLUMN priority SET NOT NULL;

;
ALTER TABLE job ALTER COLUMN priority SET DEFAULT 10;

;
CREATE INDEX job_idx_bulk_job_id on job (bulk_job_id);

;
ALTER TABLE job ADD CONSTRAINT job_fk_bulk_job_id FOREIGN KEY (bulk_job_id)
  REFERENCES bulk_job (bulk_job_id) ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

