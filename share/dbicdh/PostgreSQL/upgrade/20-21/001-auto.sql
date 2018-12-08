-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/20/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ALTER COLUMN logo SET NOT NULL;

;
ALTER TABLE site ALTER COLUMN logo SET DEFAULT '';

;
ALTER TABLE site ALTER COLUMN ssl_key SET NOT NULL;

;
ALTER TABLE site ALTER COLUMN ssl_key SET DEFAULT '';

;
ALTER TABLE site ALTER COLUMN ssl_cert SET NOT NULL;

;
ALTER TABLE site ALTER COLUMN ssl_cert SET DEFAULT '';

;
ALTER TABLE site ALTER COLUMN ssl_ca_cert SET NOT NULL;

;
ALTER TABLE site ALTER COLUMN ssl_ca_cert SET DEFAULT '';

;
ALTER TABLE site ALTER COLUMN ssl_chained_cert SET NOT NULL;

;
ALTER TABLE site ALTER COLUMN ssl_chained_cert SET DEFAULT '';

;

COMMIT;

