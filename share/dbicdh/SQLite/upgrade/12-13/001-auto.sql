-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/12/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE column_comments (
  table_name varchar(255),
  column_name varchar(255),
  comment_text text
);

;
CREATE TABLE table_comments (
  table_name varchar(255),
  comment_text text
);

;

COMMIT;

