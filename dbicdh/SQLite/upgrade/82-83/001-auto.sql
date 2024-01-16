-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/82/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/83/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "aggregation_series" (
  "aggregation_series_id" INTEGER PRIMARY KEY NOT NULL,
  "site_id" varchar(16) NOT NULL,
  "aggregation_series_uri" varchar(255) NOT NULL,
  "aggregation_series_name" varchar(255) NOT NULL,
  "publisher" varchar(255),
  "publication_place" varchar(255),
  FOREIGN KEY ("site_id") REFERENCES "site"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX "aggregation_series_idx_site_id" ON "aggregation_series" ("site_id");

;
CREATE UNIQUE INDEX "aggregation_series_uri_site_id_unique" ON "aggregation_series" ("aggregation_series_uri", "site_id");

;
CREATE TEMPORARY TABLE aggregation_temp_alter (
  aggregation_id INTEGER PRIMARY KEY NOT NULL,
  aggregation_series_id integer,
  aggregation_uri varchar(255) NOT NULL,
  aggregation_name varchar(255),
  publication_date varchar(255),
  publication_date_year integer,
  publication_date_month integer,
  publication_date_day integer,
  issue varchar(255),
  sorting_pos integer NOT NULL DEFAULT 0,
  publication_place varchar(255),
  publisher varchar(255),
  isbn varchar(32),
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (aggregation_series_id) REFERENCES aggregation_series(aggregation_series_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO aggregation_temp_alter( aggregation_id, aggregation_uri, aggregation_name, publication_date, sorting_pos, publication_place, publisher, isbn, site_id) SELECT aggregation_id, aggregation_uri, aggregation_name, publication_date, sorting_pos, publication_place, publisher, isbn, site_id FROM aggregation;

;
DROP TABLE aggregation;

;
CREATE TABLE aggregation (
  aggregation_id INTEGER PRIMARY KEY NOT NULL,
  aggregation_series_id integer,
  aggregation_uri varchar(255) NOT NULL,
  aggregation_name varchar(255),
  publication_date varchar(255),
  publication_date_year integer,
  publication_date_month integer,
  publication_date_day integer,
  issue varchar(255),
  sorting_pos integer NOT NULL DEFAULT 0,
  publication_place varchar(255),
  publisher varchar(255),
  isbn varchar(32),
  site_id varchar(16) NOT NULL,
  FOREIGN KEY (aggregation_series_id) REFERENCES aggregation_series(aggregation_series_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX aggregation_idx_aggregation00 ON aggregation (aggregation_series_id);

;
CREATE INDEX aggregation_idx_site_id02 ON aggregation (site_id);

;
CREATE INDEX aggregation_uri_amw_index02 ON aggregation (aggregation_uri);

;
CREATE UNIQUE INDEX aggregation_uri_site_id_uni00 ON aggregation (aggregation_uri, site_id);

;
INSERT INTO aggregation SELECT aggregation_id, aggregation_series_id, aggregation_uri, aggregation_name, publication_date, publication_date_year, publication_date_month, publication_date_day, issue, sorting_pos, publication_place, publisher, isbn, site_id FROM aggregation_temp_alter;

;
DROP TABLE aggregation_temp_alter;

;

COMMIT;

