-- Convert schema 'sql/AmuseWikiFarm-Schema-1.14-MySQL.sql' to 'AmuseWikiFarm::Schema v1.20':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `category_description` (
  `category_description_id` integer NOT NULL auto_increment,
  `muse_body` text NULL,
  `html_body` text NULL,
  `lang` varchar(3) NOT NULL DEFAULT 'en',
  `category_id` integer NOT NULL,
  INDEX `category_description_idx_category_id` (`category_id`),
  PRIMARY KEY (`category_description_id`),
  UNIQUE `category_id_lang_unique` (`category_id`, `lang`),
  CONSTRAINT `category_description_fk_category_id` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE attachment DROP FOREIGN KEY attachment_fk_site_id;

ALTER TABLE attachment ADD CONSTRAINT attachment_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE category DROP FOREIGN KEY category_fk_site_id;

ALTER TABLE category ADD CONSTRAINT category_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE job DROP FOREIGN KEY job_fk_site_id;

ALTER TABLE job ADD CONSTRAINT job_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE redirection DROP FOREIGN KEY redirection_fk_site_id;

ALTER TABLE redirection ADD CONSTRAINT redirection_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE revision DROP FOREIGN KEY revision_fk_title_id,
                     DROP FOREIGN KEY revision_fk_site_id;

ALTER TABLE revision ADD CONSTRAINT revision_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
                     ADD CONSTRAINT revision_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE site_link DROP FOREIGN KEY site_link_fk_site_id;

ALTER TABLE site_link ADD CONSTRAINT site_link_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE site_options DROP FOREIGN KEY site_options_fk_site_id;

ALTER TABLE site_options ADD CONSTRAINT site_options_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE title DROP FOREIGN KEY title_fk_site_id;

ALTER TABLE title ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE title_category DROP FOREIGN KEY title_category_fk_title_id,
                           DROP FOREIGN KEY title_category_fk_category_id;

ALTER TABLE title_category ADD CONSTRAINT title_category_fk_category_id FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE ON UPDATE CASCADE,
                           ADD CONSTRAINT title_category_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_role DROP FOREIGN KEY user_role_fk_role_id,
                      DROP FOREIGN KEY user_role_fk_user_id;

ALTER TABLE user_role ADD CONSTRAINT user_role_fk_role_id FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_role_fk_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_site DROP FOREIGN KEY user_site_fk_site_id,
                      DROP FOREIGN KEY user_site_fk_user_id;

ALTER TABLE user_site ADD CONSTRAINT user_site_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_site_fk_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vhost DROP FOREIGN KEY vhost_fk_site_id;

ALTER TABLE vhost ADD CONSTRAINT vhost_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;

