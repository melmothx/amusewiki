-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "job_file" (
  "filename" character varying(255) NOT NULL,
  "job_id" integer NOT NULL,
  PRIMARY KEY ("filename")
);
CREATE INDEX "job_file_idx_job_id" on "job_file" ("job_id");

;
ALTER TABLE "job_file" ADD CONSTRAINT "job_file_fk_job_id" FOREIGN KEY ("job_id")
  REFERENCES "job" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

