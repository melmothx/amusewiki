-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE bookbuilder_session (
  bookbuilder_session_id INTEGER PRIMARY KEY NOT NULL,
  token varchar(16) NOT NULL,
  site_id varchar(16) NOT NULL,
  bb_data text NOT NULL DEFAULT '{}',
  last_updated datetime NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX bookbuilder_session_idx_site_id ON bookbuilder_session (site_id);

;

COMMIT;

