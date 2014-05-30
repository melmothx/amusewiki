-- Convert schema 'sql/AmuseWikiFarm-Schema-0.08-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.09-SQLite.sql':;

BEGIN;

CREATE TABLE role (
  id INTEGER PRIMARY KEY NOT NULL,
  role varchar(128)
);

CREATE UNIQUE INDEX role_unique ON role (role);

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(128) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX username_unique ON user (username);

CREATE TABLE user_site (
  user_id integer NOT NULL,
  site_id varchar(8) NOT NULL,
  PRIMARY KEY (user_id, site_id),
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX user_site_idx_site_id ON user_site (site_id);

CREATE INDEX user_site_idx_user_id ON user_site (user_id);

DROP INDEX ;

DROP INDEX ;

DROP TABLE roles;

DROP TABLE users;


COMMIT;

