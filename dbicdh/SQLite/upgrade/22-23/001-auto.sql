-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE legacy_link (
  site_id varchar(16) NOT NULL,
  legacy_path varchar(255) NOT NULL,
  new_path varchar(255) NOT NULL,
  PRIMARY KEY (site_id, legacy_path),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX legacy_link_idx_site_id ON legacy_link (site_id);

;

COMMIT;

