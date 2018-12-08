-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/6/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN ssl_key varchar(255);

;
ALTER TABLE site ADD COLUMN ssl_cert varchar(255);

;
ALTER TABLE site ADD COLUMN ssl_ca_cert varchar(255);

;
ALTER TABLE site ADD COLUMN ssl_chained_cert varchar(255);

;

COMMIT;

