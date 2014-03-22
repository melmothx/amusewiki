-- Convert schema 'sql/AmuseWikiFarm-Schema-0.05-MySQL.sql' to 'AmuseWikiFarm::Schema v0.06':;

BEGIN;

ALTER TABLE attachment DROP FOREIGN KEY attachment_fk_site_id;

ALTER TABLE attachment ADD CONSTRAINT attachment_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE category DROP FOREIGN KEY category_fk_site_id;

ALTER TABLE category ADD CONSTRAINT category_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE job DROP FOREIGN KEY job_fk_site_id;

ALTER TABLE job ADD CONSTRAINT job_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE site ADD COLUMN bb_page_limit integer NOT NULL DEFAULT 1000,
                 CHANGE COLUMN ttdir ttdir text NOT NULL DEFAULT '';

ALTER TABLE title DROP FOREIGN KEY title_fk_site_id;

ALTER TABLE title ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE title_category DROP FOREIGN KEY title_category_fk_title_id,
                           DROP FOREIGN KEY title_category_fk_category_id;

ALTER TABLE title_category ADD CONSTRAINT title_category_fk_category_id FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE ON UPDATE CASCADE,
                           ADD CONSTRAINT title_category_fk_title_id FOREIGN KEY (title_id) REFERENCES title (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vhost DROP FOREIGN KEY vhost_fk_site_id;

ALTER TABLE vhost ADD CONSTRAINT vhost_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;

