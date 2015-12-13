-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/8/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/script/../dbicdh/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE site CHANGE COLUMN mode mode varchar(16) NOT NULL DEFAULT 'private',
                 CHANGE COLUMN magic_question magic_question varchar(255) NOT NULL DEFAULT '12 + 4 =',
                 CHANGE COLUMN magic_answer magic_answer varchar(255) NOT NULL DEFAULT '16',
                 CHANGE COLUMN secure_site secure_site integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN cgit_integration cgit_integration integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN a4_pdf a4_pdf integer(1) NOT NULL DEFAULT 0,
                 CHANGE COLUMN lt_pdf lt_pdf integer(1) NOT NULL DEFAULT 0;

;

COMMIT;

