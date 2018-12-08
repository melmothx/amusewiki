-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/17/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE title_stat_temp_alter (
  title_stat_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  title_id integer NOT NULL,
  accessed datetime NOT NULL,
  user_agent text,
  type text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO title_stat_temp_alter( title_stat_id, site_id, title_id, accessed) SELECT title_stat_id, site_id, title_id, accessed FROM title_stat;

;
DROP TABLE title_stat;

;
CREATE TABLE title_stat (
  title_stat_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  title_id integer NOT NULL,
  accessed datetime NOT NULL,
  user_agent text,
  type text,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX title_stat_idx_site_id02 ON title_stat (site_id);

;
CREATE INDEX title_stat_idx_title_id02 ON title_stat (title_id);

;
INSERT INTO title_stat SELECT title_stat_id, site_id, title_id, accessed, user_agent, type FROM title_stat_temp_alter;

;
DROP TABLE title_stat_temp_alter;

;

COMMIT;

