-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/35/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE text_internal_link (
  title_id integer NOT NULL,
  site_id varchar(16) NOT NULL,
  f_class varchar(255) NOT NULL,
  uri varchar(255) NOT NULL,
  full_link text NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX text_internal_link_idx_site_id ON text_internal_link (site_id);

;
CREATE INDEX text_internal_link_idx_title_id ON text_internal_link (title_id);

;

COMMIT;

