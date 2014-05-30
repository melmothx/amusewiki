-- Convert schema 'sql/AmuseWikiFarm-Schema-0.08-MySQL.sql' to 'AmuseWikiFarm::Schema v0.09':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE role (
  id integer NOT NULL auto_increment,
  role varchar(128) NULL,
  PRIMARY KEY (id),
  UNIQUE role_unique (role)
) ENGINE=InnoDB;

CREATE TABLE user (
  id integer NOT NULL auto_increment,
  username varchar(128) NOT NULL,
  password varchar(255) NOT NULL,
  email varchar(255) NULL,
  active integer NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE username_unique (username)
) ENGINE=InnoDB;

CREATE TABLE user_site (
  user_id integer NOT NULL,
  site_id varchar(8) NOT NULL,
  INDEX user_site_idx_site_id (site_id),
  INDEX user_site_idx_user_id (user_id),
  PRIMARY KEY (user_id, site_id),
  CONSTRAINT user_site_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT user_site_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE attachment DROP FOREIGN KEY attachment_fk_site_id;

ALTER TABLE attachment ADD CONSTRAINT attachment_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE category DROP FOREIGN KEY category_fk_site_id;

ALTER TABLE category ADD CONSTRAINT category_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE job DROP FOREIGN KEY job_fk_site_id;

ALTER TABLE job ADD CONSTRAINT job_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE revision DROP FOREIGN KEY revision_fk_site_id,
                     DROP FOREIGN KEY revision_fk_title_id;

ALTER TABLE revision ADD CONSTRAINT revision_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
                     ADD CONSTRAINT revision_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE site CHANGE COLUMN ttdir ttdir text NOT NULL DEFAULT '';

ALTER TABLE title DROP FOREIGN KEY title_fk_site_id;

ALTER TABLE title ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE title_category DROP FOREIGN KEY title_category_fk_title_id,
                           DROP FOREIGN KEY title_category_fk_category_id;

ALTER TABLE title_category ADD CONSTRAINT title_category_fk_category_id FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE ON UPDATE CASCADE,
                           ADD CONSTRAINT title_category_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_role DROP FOREIGN KEY user_role_fk_user_id,
                      DROP FOREIGN KEY user_role_fk_role_id;

ALTER TABLE user_role ADD CONSTRAINT user_role_fk_role_id FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_role_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vhost DROP FOREIGN KEY vhost_fk_site_id;

ALTER TABLE vhost ADD CONSTRAINT vhost_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

DROP TABLE roles;

ALTER TABLE users DROP FOREIGN KEY users_fk_site_id;

DROP TABLE users;


COMMIT;

