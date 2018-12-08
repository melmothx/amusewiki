-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE muse_header (
  title_id integer NOT NULL,
  muse_header varchar(255) NOT NULL,
  muse_value text,
  PRIMARY KEY (title_id, muse_header),
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX muse_header_idx_title_id ON muse_header (title_id);

;

COMMIT;

