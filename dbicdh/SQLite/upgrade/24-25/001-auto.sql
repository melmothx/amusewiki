-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/24/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/25/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE bookbuilder_profile (
  bookbuilder_profile_id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  profile_name varchar(255) NOT NULL,
  profile_data text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX bookbuilder_profile_idx_user_id ON bookbuilder_profile (user_id);

;

COMMIT;

