-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/35/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE backlink (
  title_linked_to integer NOT NULL,
  title_linked_from integer NOT NULL,
  PRIMARY KEY (title_linked_to, title_linked_from),
  FOREIGN KEY (title_linked_from) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_linked_to) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX backlink_idx_title_linked_from ON backlink (title_linked_from);

;
CREATE INDEX backlink_idx_title_linked_to ON backlink (title_linked_to);

;

COMMIT;

