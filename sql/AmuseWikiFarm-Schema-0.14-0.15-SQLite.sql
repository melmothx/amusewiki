-- Convert schema 'sql/AmuseWikiFarm-Schema-0.14-SQLite.sql' to 'sql/AmuseWikiFarm-Schema-0.15-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE user_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer NOT NULL DEFAULT 1
);

INSERT INTO user_temp_alter( id, username, password, email, active) SELECT id, username, password, email, active FROM user;

DROP TABLE user;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255),
  active integer NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX username_unique03 ON user (username);

INSERT INTO user SELECT id, username, password, email, active FROM user_temp_alter;

DROP TABLE user_temp_alter;


COMMIT;

