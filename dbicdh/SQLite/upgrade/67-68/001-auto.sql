-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/67/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE global_site_files_temp_alter (
  site_id varchar(16) NOT NULL,
  attachment_id integer,
  file_name varchar(255) NOT NULL,
  file_type varchar(255) NOT NULL,
  file_path text NOT NULL,
  image_width integer,
  image_height integer,
  PRIMARY KEY (site_id, file_name, file_type),
  FOREIGN KEY (attachment_id) REFERENCES attachment(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO global_site_files_temp_alter( site_id, attachment_id, file_name, file_type, file_path, image_width, image_height) SELECT site_id, attachment_id, file_name, file_type, file_path, image_width, image_height FROM global_site_files;

;
DROP TABLE global_site_files;

;
CREATE TABLE global_site_files (
  site_id varchar(16) NOT NULL,
  attachment_id integer,
  file_name varchar(255) NOT NULL,
  file_type varchar(255) NOT NULL,
  file_path text NOT NULL,
  image_width integer,
  image_height integer,
  PRIMARY KEY (site_id, file_name, file_type),
  FOREIGN KEY (attachment_id) REFERENCES attachment(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX global_site_files_idx_attac00 ON global_site_files (attachment_id);

;
CREATE INDEX global_site_files_idx_site_00 ON global_site_files (site_id);

;
INSERT INTO global_site_files SELECT site_id, attachment_id, file_name, file_type, file_path, image_width, image_height FROM global_site_files_temp_alter;

;
DROP TABLE global_site_files_temp_alter;

;

COMMIT;

