-- Convert schema 'sql/AmuseWikiFarm-Schema-0.15-MySQL.sql' to 'AmuseWikiFarm::Schema v0.20':;

BEGIN;

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

ALTER TABLE site ADD COLUMN sitegroup_label varchar(255) NULL,
                 ADD COLUMN catalog_label varchar(255) NULL,
                 ADD COLUMN specials_label varchar(255) NULL,
                 ADD COLUMN multilanguage integer(1) NOT NULL DEFAULT 0,
                 CHANGE COLUMN id id varchar(16) NOT NULL,
                 CHANGE COLUMN magic_question magic_question varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN magic_answer magic_answer varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN fixed_category_list fixed_category_list varchar(255) NULL,
                 CHANGE COLUMN logo logo varchar(255) NULL,
                 CHANGE COLUMN sitegroup sitegroup varchar(255) NULL,
                 CHANGE COLUMN tex tex integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN pdf pdf integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN a4_pdf a4_pdf integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN lt_pdf lt_pdf integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN html html integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN bare_html bare_html integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN epub epub integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN zip zip integer(1) NOT NULL DEFAULT 1,
                 CHANGE COLUMN ttdir ttdir varchar(255) NOT NULL DEFAULT '',
                 CHANGE COLUMN twoside twoside integer(1) NOT NULL DEFAULT 0;

ALTER TABLE title DROP FOREIGN KEY title_fk_site_id;

ALTER TABLE title ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE title_category DROP FOREIGN KEY title_category_fk_title_id,
                           DROP FOREIGN KEY title_category_fk_category_id;

ALTER TABLE title_category ADD CONSTRAINT title_category_fk_category_id FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE ON UPDATE CASCADE,
                           ADD CONSTRAINT title_category_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user CHANGE COLUMN active active integer(1) NOT NULL DEFAULT 1;

ALTER TABLE user_role DROP FOREIGN KEY user_role_fk_role_id,
                      DROP FOREIGN KEY user_role_fk_user_id;

ALTER TABLE user_role ADD CONSTRAINT user_role_fk_role_id FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_role_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE user_site DROP FOREIGN KEY user_site_fk_user_id,
                      DROP FOREIGN KEY user_site_fk_site_id;

ALTER TABLE user_site ADD CONSTRAINT user_site_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE,
                      ADD CONSTRAINT user_site_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vhost DROP FOREIGN KEY vhost_fk_site_id;

ALTER TABLE vhost ADD CONSTRAINT vhost_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;

