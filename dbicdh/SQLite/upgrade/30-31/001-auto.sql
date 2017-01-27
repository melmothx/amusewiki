-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/30/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE custom_formats (
  custom_formats_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16),
  format_name varchar(255) NOT NULL,
  bb_format varchar(16) NOT NULL DEFAULT 'pdf',
  bb_epub_embed_fonts smallint DEFAULT 1,
  bb_bcor integer NOT NULL DEFAULT 0,
  bb_beamercolortheme varchar(255) NOT NULL DEFAULT 'dove',
  bb_beamertheme varchar(255) NOT NULL DEFAULT 'default',
  bb_cover smallint DEFAULT 1,
  bb_crop_marks smallint DEFAULT 0,
  bb_crop_papersize varchar(255) NOT NULL DEFAULT 'a4',
  bb_crop_paper_height integer NOT NULL DEFAULT 0,
  bb_crop_paper_width integer NOT NULL DEFAULT 0,
  bb_crop_paper_thickness varchar(16) NOT NULL DEFAULT '0.10mm',
  bb_division integer NOT NULL DEFAULT 12,
  bb_fontsize integer NOT NULL DEFAULT 10,
  bb_headings varchar(255) NOT NULL DEFAULT '0',
  bb_imposed smallint DEFAULT 0,
  bb_mainfont varchar(255),
  bb_sansfont varchar(255),
  bb_monofont varchar(255),
  bb_nocoverpage smallint DEFAULT 0,
  bb_notoc smallint DEFAULT 0,
  bb_opening varchar(16) NOT NULL DEFAULT 'any',
  bb_papersize varchar(255) NOT NULL DEFAULT 'generic',
  bb_paper_height integer NOT NULL DEFAULT 0,
  bb_paper_width integer NOT NULL DEFAULT 0,
  bb_schema varchar(255) NOT NULL DEFAULT '2up',
  bb_signature integer NOT NULL DEFAULT 0,
  bb_twoside smallint DEFAULT 0,
  bb_unbranded smallint DEFAULT 0,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX custom_formats_idx_site_id ON custom_formats (site_id);

;
ALTER TABLE bookbuilder_profile ADD COLUMN custom_formats_id integer;

;
CREATE INDEX bookbuilder_profile_idx_custom_formats_id ON bookbuilder_profile (custom_formats_id);

;

;

COMMIT;

