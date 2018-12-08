-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/20/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site CHANGE COLUMN logo logo varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN ssl_key ssl_key varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN ssl_cert ssl_cert varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN ssl_ca_cert ssl_ca_cert varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN ssl_chained_cert ssl_chained_cert varchar(255) NOT NULL DEFAULT '';

;

COMMIT;

