-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/6/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN ssl_key character varying(255);

;
ALTER TABLE site ADD COLUMN ssl_cert character varying(255);

;
ALTER TABLE site ADD COLUMN ssl_ca_cert character varying(255);

;
ALTER TABLE site ADD COLUMN ssl_chained_cert character varying(255);

;

COMMIT;

