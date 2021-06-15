-- Convert schema '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/65/001-auto.yml' to '/home/marco/amw/AmuseWikiFarm/dbicdh/_source/deploy/66/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE custom_formats_temp_alter (
  custom_formats_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  format_name varchar(255) NOT NULL,
  format_description text,
  format_alias varchar(8),
  format_code varchar(8),
  format_priority integer NOT NULL DEFAULT 0,
  active smallint DEFAULT 1,
  bb_format varchar(16) NOT NULL DEFAULT 'pdf',
  bb_epub_embed_fonts smallint DEFAULT 1,
  bb_bcor integer NOT NULL DEFAULT 0,
  bb_beamercolortheme varchar(32) NOT NULL DEFAULT 'dove',
  bb_beamertheme varchar(32) NOT NULL DEFAULT 'default',
  bb_cover smallint DEFAULT 1,
  bb_crop_marks smallint DEFAULT 0,
  bb_crop_papersize varchar(32) NOT NULL DEFAULT 'a4',
  bb_crop_paper_height integer NOT NULL DEFAULT 0,
  bb_crop_paper_width integer NOT NULL DEFAULT 0,
  bb_crop_paper_thickness varchar(16) NOT NULL DEFAULT '0.10mm',
  bb_division integer NOT NULL DEFAULT 12,
  bb_fontsize integer NOT NULL DEFAULT 10,
  bb_headings varchar(64) NOT NULL DEFAULT '0',
  bb_imposed smallint DEFAULT 0,
  bb_mainfont varchar(255),
  bb_sansfont varchar(255),
  bb_monofont varchar(255),
  bb_nocoverpage smallint DEFAULT 0,
  bb_coverpage_only_if_toc smallint DEFAULT 0,
  bb_nofinalpage smallint DEFAULT 0,
  bb_notoc smallint DEFAULT 0,
  bb_impressum smallint DEFAULT 0,
  bb_sansfontsections smallint DEFAULT 0,
  bb_nobold smallint DEFAULT 0,
  bb_secondary_footnotes_alpha smallint DEFAULT 0,
  bb_start_with_empty_page smallint DEFAULT 0,
  bb_continuefootnotes smallint DEFAULT 0,
  bb_centerchapter smallint DEFAULT 0,
  bb_centersection smallint DEFAULT 0,
  bb_opening varchar(16) NOT NULL DEFAULT 'any',
  bb_papersize varchar(32) NOT NULL DEFAULT 'generic',
  bb_paper_height integer NOT NULL DEFAULT 0,
  bb_paper_width integer NOT NULL DEFAULT 0,
  bb_schema varchar(64) NOT NULL DEFAULT '2up',
  bb_signature integer NOT NULL DEFAULT 0,
  bb_signature_2up varchar(8) NOT NULL DEFAULT '40-80',
  bb_signature_4up varchar(8) NOT NULL DEFAULT '40-80',
  bb_twoside smallint DEFAULT 0,
  bb_unbranded smallint DEFAULT 0,
  bb_areaset_height integer NOT NULL DEFAULT 0,
  bb_areaset_width integer NOT NULL DEFAULT 0,
  bb_fussy_last_word smallint DEFAULT 0,
  bb_tex_emergencystretch integer NOT NULL DEFAULT 30,
  bb_tex_tolerance integer NOT NULL DEFAULT 200,
  bb_ignore_cover smallint DEFAULT 0,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO custom_formats_temp_alter( custom_formats_id, site_id, format_name, format_description, format_alias, format_code, format_priority, active, bb_format, bb_epub_embed_fonts, bb_bcor, bb_beamercolortheme, bb_beamertheme, bb_cover, bb_crop_marks, bb_crop_papersize, bb_crop_paper_height, bb_crop_paper_width, bb_crop_paper_thickness, bb_division, bb_fontsize, bb_headings, bb_imposed, bb_mainfont, bb_sansfont, bb_monofont, bb_nocoverpage, bb_coverpage_only_if_toc, bb_nofinalpage, bb_notoc, bb_impressum, bb_sansfontsections, bb_nobold, bb_secondary_footnotes_alpha, bb_start_with_empty_page, bb_continuefootnotes, bb_centerchapter, bb_centersection, bb_opening, bb_papersize, bb_paper_height, bb_paper_width, bb_schema, bb_signature, bb_signature_2up, bb_signature_4up, bb_twoside, bb_unbranded, bb_areaset_height, bb_areaset_width, bb_fussy_last_word, bb_tex_emergencystretch, bb_tex_tolerance, bb_ignore_cover) SELECT custom_formats_id, site_id, format_name, format_description, format_alias, format_code, format_priority, active, bb_format, bb_epub_embed_fonts, bb_bcor, bb_beamercolortheme, bb_beamertheme, bb_cover, bb_crop_marks, bb_crop_papersize, bb_crop_paper_height, bb_crop_paper_width, bb_crop_paper_thickness, bb_division, bb_fontsize, bb_headings, bb_imposed, bb_mainfont, bb_sansfont, bb_monofont, bb_nocoverpage, bb_coverpage_only_if_toc, bb_nofinalpage, bb_notoc, bb_impressum, bb_sansfontsections, bb_nobold, bb_secondary_footnotes_alpha, bb_start_with_empty_page, bb_continuefootnotes, bb_centerchapter, bb_centersection, bb_opening, bb_papersize, bb_paper_height, bb_paper_width, bb_schema, bb_signature, bb_signature_2up, bb_signature_4up, bb_twoside, bb_unbranded, bb_areaset_height, bb_areaset_width, bb_fussy_last_word, bb_tex_emergencystretch, bb_tex_tolerance, bb_ignore_cover FROM custom_formats;

;
DROP TABLE custom_formats;

;
CREATE TABLE custom_formats (
  custom_formats_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  format_name varchar(255) NOT NULL,
  format_description text,
  format_alias varchar(8),
  format_code varchar(8),
  format_priority integer NOT NULL DEFAULT 0,
  active smallint DEFAULT 1,
  bb_format varchar(16) NOT NULL DEFAULT 'pdf',
  bb_epub_embed_fonts smallint DEFAULT 1,
  bb_bcor integer NOT NULL DEFAULT 0,
  bb_beamercolortheme varchar(32) NOT NULL DEFAULT 'dove',
  bb_beamertheme varchar(32) NOT NULL DEFAULT 'default',
  bb_cover smallint DEFAULT 1,
  bb_crop_marks smallint DEFAULT 0,
  bb_crop_papersize varchar(32) NOT NULL DEFAULT 'a4',
  bb_crop_paper_height integer NOT NULL DEFAULT 0,
  bb_crop_paper_width integer NOT NULL DEFAULT 0,
  bb_crop_paper_thickness varchar(16) NOT NULL DEFAULT '0.10mm',
  bb_division integer NOT NULL DEFAULT 12,
  bb_fontsize integer NOT NULL DEFAULT 10,
  bb_headings varchar(64) NOT NULL DEFAULT '0',
  bb_imposed smallint DEFAULT 0,
  bb_mainfont varchar(255),
  bb_sansfont varchar(255),
  bb_monofont varchar(255),
  bb_nocoverpage smallint DEFAULT 0,
  bb_coverpage_only_if_toc smallint DEFAULT 0,
  bb_nofinalpage smallint DEFAULT 0,
  bb_notoc smallint DEFAULT 0,
  bb_impressum smallint DEFAULT 0,
  bb_sansfontsections smallint DEFAULT 0,
  bb_nobold smallint DEFAULT 0,
  bb_secondary_footnotes_alpha smallint DEFAULT 0,
  bb_start_with_empty_page smallint DEFAULT 0,
  bb_continuefootnotes smallint DEFAULT 0,
  bb_centerchapter smallint DEFAULT 0,
  bb_centersection smallint DEFAULT 0,
  bb_opening varchar(16) NOT NULL DEFAULT 'any',
  bb_papersize varchar(32) NOT NULL DEFAULT 'generic',
  bb_paper_height integer NOT NULL DEFAULT 0,
  bb_paper_width integer NOT NULL DEFAULT 0,
  bb_schema varchar(64) NOT NULL DEFAULT '2up',
  bb_signature integer NOT NULL DEFAULT 0,
  bb_signature_2up varchar(8) NOT NULL DEFAULT '40-80',
  bb_signature_4up varchar(8) NOT NULL DEFAULT '40-80',
  bb_twoside smallint DEFAULT 0,
  bb_unbranded smallint DEFAULT 0,
  bb_areaset_height integer NOT NULL DEFAULT 0,
  bb_areaset_width integer NOT NULL DEFAULT 0,
  bb_fussy_last_word smallint DEFAULT 0,
  bb_tex_emergencystretch integer NOT NULL DEFAULT 30,
  bb_tex_tolerance integer NOT NULL DEFAULT 200,
  bb_ignore_cover smallint DEFAULT 0,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX custom_formats_idx_site_id02 ON custom_formats (site_id);

;
CREATE UNIQUE INDEX site_id_format_alias_unique02 ON custom_formats (site_id, format_alias);

;
CREATE UNIQUE INDEX site_id_format_code_unique02 ON custom_formats (site_id, format_code);

;
INSERT INTO custom_formats SELECT custom_formats_id, site_id, format_name, format_description, format_alias, format_code, format_priority, active, bb_format, bb_epub_embed_fonts, bb_bcor, bb_beamercolortheme, bb_beamertheme, bb_cover, bb_crop_marks, bb_crop_papersize, bb_crop_paper_height, bb_crop_paper_width, bb_crop_paper_thickness, bb_division, bb_fontsize, bb_headings, bb_imposed, bb_mainfont, bb_sansfont, bb_monofont, bb_nocoverpage, bb_coverpage_only_if_toc, bb_nofinalpage, bb_notoc, bb_impressum, bb_sansfontsections, bb_nobold, bb_secondary_footnotes_alpha, bb_start_with_empty_page, bb_continuefootnotes, bb_centerchapter, bb_centersection, bb_opening, bb_papersize, bb_paper_height, bb_paper_width, bb_schema, bb_signature, bb_signature_2up, bb_signature_4up, bb_twoside, bb_unbranded, bb_areaset_height, bb_areaset_width, bb_fussy_last_word, bb_tex_emergencystretch, bb_tex_tolerance, bb_ignore_cover FROM custom_formats_temp_alter;

;
DROP TABLE custom_formats_temp_alter;

;

COMMIT;

