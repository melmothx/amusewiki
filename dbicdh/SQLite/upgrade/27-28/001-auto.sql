-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/27/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE bulk_job (
  bulk_job_id INTEGER PRIMARY KEY NOT NULL,
  task varchar(32),
  created datetime NOT NULL,
  completed datetime,
  site_id varchar(16) NOT NULL,
  username varchar(255),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX bulk_job_idx_site_id ON bulk_job (site_id);

;
CREATE TEMPORARY TABLE job_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  bulk_job_id integer,
  task varchar(32),
  payload text,
  status varchar(32),
  created datetime NOT NULL,
  completed datetime,
  priority integer NOT NULL DEFAULT 10,
  produced varchar(255),
  username varchar(255),
  errors text,
  FOREIGN KEY (bulk_job_id) REFERENCES bulk_job(bulk_job_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO job_temp_alter( id, site_id, task, payload, status, created, completed, priority, produced, username, errors) SELECT id, site_id, task, payload, status, created, completed, priority, produced, username, errors FROM job;

;
DROP TABLE job;

;
CREATE TABLE job (
  id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  bulk_job_id integer,
  task varchar(32),
  payload text,
  status varchar(32),
  created datetime NOT NULL,
  completed datetime,
  priority integer NOT NULL DEFAULT 10,
  produced varchar(255),
  username varchar(255),
  errors text,
  FOREIGN KEY (bulk_job_id) REFERENCES bulk_job(bulk_job_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX job_idx_bulk_job_id02 ON job (bulk_job_id);

;
CREATE INDEX job_idx_site_id02 ON job (site_id);

;
INSERT INTO job SELECT id, site_id, bulk_job_id, task, payload, status, created, completed, priority, produced, username, errors FROM job_temp_alter;

;
DROP TABLE job_temp_alter;

;

COMMIT;

