-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE monthly_archive (
  monthly_archive_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  month integer(2) NOT NULL,
  year integer(4) NOT NULL,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX monthly_archive_idx_site_id ON monthly_archive (site_id);

;
CREATE UNIQUE INDEX site_id_month_year_unique ON monthly_archive (site_id, month, year);

;
CREATE TABLE text_month (
  title_id integer NOT NULL,
  monthly_archive_id integer NOT NULL,
  PRIMARY KEY (title_id, monthly_archive_id),
  FOREIGN KEY (monthly_archive_id) REFERENCES monthly_archive(monthly_archive_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX text_month_idx_monthly_archive_id ON text_month (monthly_archive_id);

;
CREATE INDEX text_month_idx_title_id ON text_month (title_id);

;

COMMIT;

