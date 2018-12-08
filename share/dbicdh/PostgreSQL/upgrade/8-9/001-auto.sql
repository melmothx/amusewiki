-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/8/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site ALTER COLUMN mode SET DEFAULT 'private';

;
ALTER TABLE site ALTER COLUMN magic_question SET DEFAULT '12 + 4 =';

;
ALTER TABLE site ALTER COLUMN magic_answer SET DEFAULT '16';

;
ALTER TABLE site ALTER COLUMN secure_site SET DEFAULT 1;

;
ALTER TABLE site ALTER COLUMN cgit_integration SET DEFAULT 1;

;
ALTER TABLE site ALTER COLUMN a4_pdf SET DEFAULT 0;

;
ALTER TABLE site ALTER COLUMN lt_pdf SET DEFAULT 0;

;

COMMIT;

