-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/4/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE job_file (
  filename varchar(255) NOT NULL,
  job_id integer NOT NULL,
  PRIMARY KEY (filename),
  FOREIGN KEY (job_id) REFERENCES job(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX job_file_idx_job_id ON job_file (job_id);

;

COMMIT;

