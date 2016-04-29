-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/14/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ADD COLUMN acme_certificate integer(1) NOT NULL DEFAULT 0;

;

COMMIT;

