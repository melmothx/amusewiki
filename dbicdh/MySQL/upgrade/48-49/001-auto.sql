-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/48/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/49/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE title CHANGE COLUMN title title text NULL,
                  CHANGE COLUMN subtitle subtitle text NULL,
                  CHANGE COLUMN date date text NULL,
                  CHANGE COLUMN notes notes text NULL,
                  CHANGE COLUMN source source text NULL,
                  CHANGE COLUMN list_title list_title text NULL,
                  CHANGE COLUMN author author text NULL,
                  CHANGE COLUMN deleted deleted text NULL,
                  CHANGE COLUMN text_structure text_structure text NULL,
                  CHANGE COLUMN teaser teaser text NULL;

;

COMMIT;

