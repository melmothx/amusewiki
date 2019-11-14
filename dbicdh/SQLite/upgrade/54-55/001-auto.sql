-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/54/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/55/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE title_attachment (
  title_id integer NOT NULL,
  attachment_id integer NOT NULL,
  PRIMARY KEY (title_id, attachment_id),
  FOREIGN KEY (attachment_id) REFERENCES attachment(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX title_attachment_idx_attachment_id ON title_attachment (attachment_id);

;
CREATE INDEX title_attachment_idx_title_id ON title_attachment (title_id);

;

COMMIT;

