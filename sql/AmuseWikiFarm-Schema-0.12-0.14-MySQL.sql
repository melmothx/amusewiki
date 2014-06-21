-- Convert schema 'sql/AmuseWikiFarm-Schema-0.12-MySQL.sql' to 'AmuseWikiFarm::Schema v0.14':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE redirection (
  id integer NOT NULL auto_increment,
  uri varchar(255) NOT NULL,
  type varchar(16) NOT NULL,
  redirect varchar(255) NOT NULL,
  site_id varchar(8) NOT NULL,
  INDEX redirection_idx_site_id (site_id),
  PRIMARY KEY (id),
  UNIQUE uri_type_site_id_unique (uri, type, site_id),
  CONSTRAINT redirection_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE
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

ALTER TABLE user_site DROP FOREIGN KEY user_site_fk_user_id,
                      DROP FOREIGN KEY user_site_fk_site_id;

ALTER TABLE user_site ADD CONSTRAINT user_site_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_site_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vhost DROP FOREIGN KEY vhost_fk_site_id;

ALTER TABLE vhost ADD CONSTRAINT vhost_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;

