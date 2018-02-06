-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/45/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/46/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE amw_session (
  session_id varchar(255) NOT NULL,
  site_id varchar(16) NOT NULL,
  expires integer,
  session_data blob,
  flash_data blob,
  generic_data blob,
  PRIMARY KEY (session_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX amw_session_idx_site_id ON amw_session (site_id);

;

COMMIT;

