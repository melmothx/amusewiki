-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/16/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE title_stat (
  title_stat_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  title_id integer NOT NULL,
  accessed datetime NOT NULL,
  notes text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX title_stat_idx_site_id ON title_stat (site_id);

;
CREATE INDEX title_stat_idx_title_id ON title_stat (title_id);

;

COMMIT;

