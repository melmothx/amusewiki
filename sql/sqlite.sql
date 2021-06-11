PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS vhost;
DROP TABLE IF EXISTS site;
DROP TABLE IF EXISTS title_author;
DROP TABLE IF EXISTS title;
DROP TABLE IF EXISTS author;

CREATE TABLE vhost (
       name VARCHAR(255) PRIMARY KEY,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE site (
       id VARCHAR(16) PRIMARY KEY,
       mode VARCHAR(16) NOT NULL DEFAULT 'private',
       locale VARCHAR(3) NOT NULL DEFAULT 'en',

       -- TODO: move these things in a setting table, it's too cluttered
       magic_question VARCHAR(255) NOT NULL DEFAULT '12 + 4 =',
       magic_answer   VARCHAR(255) NOT NULL DEFAULT '16',

       -- list of space separated category codes, if you want this feature
       fixed_category_list TEXT,

       sitename VARCHAR(255) NOT NULL DEFAULT '',
       siteslogan VARCHAR(255) NOT NULL DEFAULT '',
       theme VARCHAR(32) NOT NULL DEFAULT '',
       logo VARCHAR(255) NOT NULL DEFAULT '', -- could be a path, so keep it at 255
       mail_notify TEXT,
       mail_from   TEXT,

       -- canonical server name
       canonical VARCHAR(255) NOT NULL,
       secure_site INTEGER(1) NOT NULL DEFAULT 1,
       secure_site_only INTEGER(1) NOT NULL DEFAULT 0,

       -- site group
       sitegroup VARCHAR(255) NOT NULL DEFAULT '',

       -- cgit integration
       cgit_integration INTEGER(1) NOT NULL DEFAULT 1,

       -- ssl options
       ssl_key VARCHAR(255) NOT NULL DEFAULT '',
       ssl_cert VARCHAR(255) NOT NULL DEFAULT '',
       ssl_ca_cert VARCHAR(255) NOT NULL DEFAULT '',
       ssl_chained_cert VARCHAR(255) NOT NULL DEFAULT '',
       acme_certificate INTEGER(1) NOT NULL DEFAULT 0,

       -- boolean for multilanguage
       multilanguage VARCHAR(255) NOT NULL DEFAULT '',

       -- need a webserver entry?
       active INTEGER(1) NOT NULL DEFAULT 1,

       -- blog style?
       blog_style INTEGER(1) NOT NULL DEFAULT 0,

       -- book builder page limit
       bb_page_limit INTEGER NOT NULL DEFAULT 1000,
       -- formats
       tex       INTEGER(1) NOT NULL DEFAULT 1,
       pdf       INTEGER(1) NOT NULL DEFAULT 1,
       a4_pdf    INTEGER(1) NOT NULL DEFAULT 0,
       lt_pdf    INTEGER(1) NOT NULL DEFAULT 0,
       sl_pdf    INTEGER(1) NOT NULL DEFAULT 0,
       html      INTEGER(1) NOT NULL DEFAULT 1,
       bare_html INTEGER(1) NOT NULL DEFAULT 1,
       epub      INTEGER(1) NOT NULL DEFAULT 1,
       zip       INTEGER(1) NOT NULL DEFAULT 1,
       ttdir     VARCHAR(255) NOT NULL DEFAULT '',
       -- tex options
       papersize VARCHAR(64) NOT NULL DEFAULT '', -- will pick the generic
       division INTEGER NOT NULL DEFAULT '12',
       bcor VARCHAR(16) NOT NULL DEFAULT '0mm',
       fontsize INTEGER NOT NULL DEFAULT '10',
       mainfont VARCHAR(255) NOT NULL DEFAULT 'CMU Serif',
       sansfont VARCHAR(255) NOT NULL DEFAULT 'CMU Sans Serif',
       monofont VARCHAR(255) NOT NULL DEFAULT 'CMU Typewriter Text',
       beamertheme VARCHAR(255) NOT NULL DEFAULT 'default',
       beamercolortheme VARCHAR(255) NOT NULL DEFAULT 'dove',
       nocoverpage INTEGER(1) NOT NULL DEFAULT 0,
       logo_with_sitename INTEGER(1) NOT NULL DEFAULT 0,
       opening VARCHAR(16) NOT NULL DEFAULT 'any',
       twoside INTEGER(1) NOT NULL DEFAULT 0,
       binary_upload_max_size_in_mega INTEGER NOT NULL DEFAULT 8,
       git_token TEXT,
       last_updated DATETIME
);

CREATE UNIQUE INDEX unique_site_canonical ON site (canonical);

CREATE TABLE site_options (
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
               ON DELETE CASCADE ON UPDATE CASCADE,
       option_name VARCHAR(64),
       option_value TEXT,
       PRIMARY KEY (site_id, option_name)
);

CREATE TABLE global_site_files (
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
               ON DELETE CASCADE ON UPDATE CASCADE,
       attachment_id INTEGER NULL REFERENCES attachment(id)
               ON DELETE CASCADE ON UPDATE CASCADE,
       file_name VARCHAR(255) NOT NULL,
       file_type VARCHAR(255) NOT NULL,
       file_path TEXT NOT NULL,
       image_width INTEGER NULL,
       image_height INTEGER NULL,
       PRIMARY KEY (site_id, file_name)
);

CREATE TABLE custom_formats (
       custom_formats_id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
               ON DELETE CASCADE ON UPDATE CASCADE,
       format_name VARCHAR(255) NOT NULL,
       format_description TEXT,
       format_alias VARCHAR(8) NULL,
       format_code VARCHAR(8) NULL,
       format_priority INTEGER NOT NULL DEFAULT 0,
       active SMALLINT DEFAULT 1,
       bb_format VARCHAR(16) NOT NULL DEFAULT 'pdf',
       bb_epub_embed_fonts SMALLINT DEFAULT 1,
       bb_bcor INTEGER NOT NULL DEFAULT 0,
       bb_beamercolortheme VARCHAR(255) NOT NULL DEFAULT 'dove',
       bb_beamertheme VARCHAR(255) NOT NULL DEFAULT 'default',
       bb_cover  SMALLINT DEFAULT 1,
       bb_crop_marks SMALLINT DEFAULT 0,
       bb_crop_papersize VARCHAR(255) NOT NULL DEFAULT 'a4',
       bb_crop_paper_height INTEGER NOT NULL DEFAULT 0,
       bb_crop_paper_width  INTEGER NOT NULL DEFAULT 0,
       bb_crop_paper_thickness  VARCHAR(16) NOT NULL DEFAULT '0.10mm',
       bb_division INTEGER NOT NULL DEFAULT 12,
       bb_fontsize INTEGER NOT NULL DEFAULT 10,
       bb_headings VARCHAR(255) NOT NULL DEFAULT '0',
       bb_imposed  SMALLINT DEFAULT 0,
       bb_mainfont VARCHAR(255),
       bb_sansfont VARCHAR(255),
       bb_monofont VARCHAR(255),
       bb_nocoverpage SMALLINT DEFAULT 0,
       bb_coverpage_only_if_toc SMALLINT DEFAULT 0,
       bb_nofinalpage SMALLINT DEFAULT 0,
       bb_notoc SMALLINT DEFAULT 0,
       bb_impressum        SMALLINT DEFAULT 0,
       bb_sansfontsections SMALLINT DEFAULT 0,
       bb_nobold SMALLINT DEFAULT 0,
       bb_secondary_footnotes_alpha SMALLINT DEFAULT 0,
       bb_start_with_empty_page SMALLINT DEFAULT 0,
       bb_continuefootnotes SMALLINT DEFAULT 0,
       bb_centerchapter     SMALLINT DEFAULT 0,
       bb_centersection     SMALLINT DEFAULT 0,
       bb_opening VARCHAR(16) NOT NULL DEFAULT 'any',
       bb_papersize VARCHAR(255) NOT NULL DEFAULT 'generic',
       bb_paper_height INTEGER NOT NULL DEFAULT 0,
       bb_paper_width INTEGER NOT NULL DEFAULT 0,
       bb_schema VARCHAR(255) NOT NULL DEFAULT '2up',
       bb_signature INTEGER NOT NULL DEFAULT 0,
       bb_signature_2up VARCHAR(8) NOT NULL DEFAULT '40-80',
       bb_signature_4up VARCHAR(8) NOT NULL DEFAULT '40-80',
       bb_twoside SMALLINT DEFAULT 0,
       bb_unbranded SMALLINT DEFAULT 0,
       bb_areaset_height  INTEGER NOT NULL DEFAULT 0,
       bb_areaset_width   INTEGER NOT NULL DEFAULT 0,
       bb_geometry_top_margin INTEGER NOT NULL DEFAULT 0,
       bb_geometry_outer_margin INTEGER NOT NULL DEFAULT 0,
       bb_fussy_last_word SMALLINT DEFAULT 0,
       bb_tex_emergencystretch INTEGER NOT NULL DEFAULT 30,
       bb_tex_tolerance INTEGER NOT NULL DEFAULT 200,
       bb_ignore_cover SMALLINT DEFAULT 0
);

CREATE UNIQUE INDEX unique_custom_formats_site_code ON custom_formats (site_id,format_code);
CREATE UNIQUE INDEX unique_custom_formats_site_alias ON custom_formats (site_id,format_alias);

-- https://sqlite.org/faq.html#q26
-- Perhaps you are referring to the following statement from SQL92:

--     A unique constraint is satisfied if and only if no two rows in
--     a table have the same non-null values in the unique columns.
--
-- That statement is ambiguous, having at least two possible
-- interpretations:
--
--     A unique constraint is satisfied if and only if no two rows in
--     a table have the same values and have non-null values in the
--     unique columns.
--
--         A unique constraint is satisfied if and only if no two rows
--         in a table have the same values in the subset of unique
--         columns that are not null.
--
-- SQLite follows interpretation (1), as does PostgreSQL, MySQL,
-- Oracle, and Firebird. It is true that Informix and Microsoft SQL
-- Server use interpretation (2), however we the SQLite developers
-- hold that interpretation (1) is the most natural reading of the
-- requirement and we also want to maximize compatibility with other
-- SQL database engines, and most other database engines also go with
-- (1), so that is what SQLite does.



CREATE TABLE users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       username VARCHAR(255) NOT NULL,
       password VARCHAR(255) NOT NULL,
       email    VARCHAR(255),
       created_by VARCHAR(255),
       active   INTEGER(1) NOT NULL DEFAULT 1,
       edit_option_preview_box_height INTEGER NOT NULL DEFAULT 500,
       edit_option_show_filters INTEGER(1) NOT NULL DEFAULT 1,
       edit_option_show_cheatsheet INTEGER(1) NOT NULL DEFAULT 1,
       edit_option_page_left_bs_columns INTEGER DEFAULT 6,
       preferred_language VARCHAR(8),
       reset_token TEXT NULL,
       reset_until INTEGER NULL
);

CREATE UNIQUE INDEX unique_username ON users (username);


CREATE TABLE roles (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       role VARCHAR(128)
);

CREATE UNIQUE INDEX unique_role ON roles (role);

CREATE TABLE user_site (
       user_id INTEGER NOT NULL REFERENCES users(id)
                       ON DELETE CASCADE ON UPDATE CASCADE,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       PRIMARY KEY (user_id, site_id)
);

CREATE TABLE user_role (
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
        role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (user_id, role_id)
);

CREATE TABLE bookbuilder_profile (
       bookbuilder_profile_id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id)
                       ON DELETE CASCADE ON UPDATE CASCADE,
       profile_name VARCHAR(255) NOT NULL,
       profile_data TEXT NOT NULL
);

CREATE TABLE bookbuilder_session (
       bookbuilder_session_id INTEGER PRIMARY KEY AUTOINCREMENT,
       token VARCHAR(16) NOT NULL,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       bb_data TEXT NOT NULL,
       last_updated DATETIME NOT NULL -- internal
);

CREATE TABLE revision (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       f_full_path_name TEXT,
       message TEXT,
       status VARCHAR(16) NOT NULL DEFAULT 'editing',
       session_id VARCHAR(255), -- can be null or false
       username  VARCHAR(255), -- can be null, we don't really care
       updated DATETIME NOT NULL -- internal
);

CREATE TABLE bulk_job (
       bulk_job_id INTEGER PRIMARY KEY AUTOINCREMENT,
       task      VARCHAR(32),
       created   DATETIME NOT NULL,
       started   DATETIME,
       completed DATETIME,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       status    VARCHAR(32),
       username  VARCHAR(255)
);


CREATE TABLE job (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       bulk_job_id INTEGER NULL REFERENCES bulk_job(bulk_job_id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       task      VARCHAR(32),
       payload   TEXT, -- the JSON stuff
       status    VARCHAR(32),
       created   DATETIME NOT NULL,
       started   DATETIME,
       completed DATETIME,
       priority  INTEGER NOT NULL DEFAULT 10,
       produced  VARCHAR(255),
       username  VARCHAR(255),
       errors    TEXT
);

CREATE INDEX job_status_index ON job (status);

CREATE TABLE job_file (
       filename VARCHAR(255) NOT NULL PRIMARY KEY,
       slot VARCHAR(255) NOT NULL DEFAULT '',
       job_id INTEGER NOT NULL REFERENCES job(id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE title (
        id          INTEGER PRIMARY KEY,

        -- from the .muse file
        title       TEXT,
        subtitle    TEXT,

        -- 3 letters, as per doc
        lang        VARCHAR(3) NOT NULL DEFAULT 'en',

        date        TEXT,
        notes       TEXT,
        source      TEXT,

        -- sorting only, as per doc
        list_title  TEXT,

        -- display only, as per doc
        author      TEXT,

        -- from tabula rasa
        -- to identify translations texts across libraries
        uid         VARCHAR(255) NOT NULL DEFAULT '',
        -- to attach files
        attach      TEXT,
        -- to overwrite the timestamp
        pubdate     DATETIME NOT NULL,
        status      VARCHAR(16) NOT NULL DEFAULT 'unpublished',

        -- parent/child relationship. This is not an hard rel, it's
        -- just a string
        parent      VARCHAR(255),

        publisher TEXT,
        isbn TEXT,
        rights TEXT,
        seriesname TEXT,
        seriesnumber TEXT,

        -- from the scanner
        f_path      TEXT NOT NULL,
        f_name      VARCHAR(255) NOT NULL,
        f_archive_rel_path VARCHAR(32) NOT NULL,
        f_timestamp DATETIME NOT NULL,
        f_timestamp_epoch INTEGER NOT NULL DEFAULT 0,
        f_full_path_name TEXT NOT NULL,
        f_suffix    VARCHAR(16) NOT NULL,
        f_class     VARCHAR(16) NOT NULL,

        uri         VARCHAR(255) NOT NULL,
        deleted     TEXT,

        slides      INTEGER(1) NOT NULL DEFAULT 0,

        text_structure TEXT,

        cover VARCHAR(255) NOT NULL DEFAULT '',
        teaser TEXT,

        sorting_pos INTEGER NOT NULL DEFAULT 0,
        sku VARCHAR(64) NOT NULL DEFAULT '',
        text_qualification VARCHAR(32),
        text_size INTEGER NOT NULL DEFAULT 0,
        attachment_index INTEGER NOT NULL DEFAULT 0,
        blob_container INTEGER(1) NOT NULL DEFAULT 0,
        site_id     VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_text ON title (uri, f_class, site_id);

CREATE TABLE text_internal_link (
        title_id INTEGER NOT NULL REFERENCES title(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
        f_class VARCHAR(255) NOT NULL,
        uri VARCHAR(255) NOT NULL,
        full_link TEXT NOT NULL
);

CREATE TABLE text_part (
        title_id INTEGER NOT NULL REFERENCES title(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        part_index VARCHAR(16) NOT NULL,
        part_level INTEGER NOT NULL,
        part_title TEXT NOT NULL,
        part_size INTEGER NOT NULL,
        toc_index INTEGER NOT NULL,
        part_order INTEGER NOT NULL,
        PRIMARY KEY("title_id", "part_index")
);


CREATE TABLE redirection (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       uri VARCHAR(255) NOT NULL,
       -- this is text, special, author, topic and eventual other
       type VARCHAR(16) NOT NULL,
       -- the redirection
       redirect VARCHAR(255) NOT NULL,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_redirection ON redirection (uri, type, site_id);


-- 'book_author' is a many-to-many join table between books & authors
CREATE TABLE title_category (
        title_id     INTEGER NOT NULL REFERENCES title(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        category_id  INTEGER NOT NULL REFERENCES category(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (title_id, category_id)
);
CREATE TABLE category (
        id          INTEGER PRIMARY KEY,
        name  TEXT,
        uri   VARCHAR(255) NOT NULL,
        type  VARCHAR(16) NOT NULL,
        sorting_pos INTEGER NOT NULL DEFAULT 0,
        text_count INTEGER NOT NULL DEFAULT 0,
        active SMALLINT NOT NULL DEFAULT 1,
        site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_category ON category (uri, site_id, type);

-- site here is not needed, because it's already known by the category.
CREATE TABLE category_description (
       category_description_id INTEGER PRIMARY KEY,
       muse_body TEXT,
       html_body TEXT,
       lang VARCHAR(3) NOT NULL DEFAULT 'en',
       last_modified_by VARCHAR(255),
       category_id INTEGER NOT NULL
                   REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX unique_category_description ON category_description(category_id, lang);

CREATE TABLE site_category_type (
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       category_type VARCHAR(16) NOT NULL,
       active SMALLINT NOT NULL DEFAULT 1,
       priority INTEGER NOT NULL DEFAULT 0,
       name_singular VARCHAR(255) NOT NULL,
       name_plural VARCHAR(255) NOT NULL,
       PRIMARY KEY (site_id, category_type)
);

CREATE TABLE attachment (
       id INTEGER PRIMARY KEY,
       f_path      TEXT NOT NULL,
       f_name      VARCHAR(255) NOT NULL,
       f_archive_rel_path VARCHAR(32) NOT NULL,
       f_timestamp DATETIME NOT NULL,
       f_timestamp_epoch INTEGER NOT NULL DEFAULT 0,
       f_full_path_name TEXT NOT NULL,
       f_suffix    VARCHAR(16) NOT NULL,
       f_class     VARCHAR(16) NOT NULL,
       uri   VARCHAR(255) NOT NULL,
       title_muse TEXT,
       comment_muse TEXT,
       title_html TEXT,
       comment_html TEXT,
       mime_type VARCHAR(255),
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX unique_attachment ON attachment (uri, site_id);

CREATE TABLE site_link (
       url VARCHAR(255) NOT NULL,
       label VARCHAR(255) NOT NULL,
       sorting_pos INTEGER NOT NULL DEFAULT 0,
       menu VARCHAR(32) NOT NULL DEFAULT 'specials',
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE title_stat (
       title_stat_id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       title_id INTEGER NOT NULL REFERENCES title(id)
                                 ON DELETE CASCADE ON UPDATE CASCADE,
       accessed DATETIME NOT NULL,
       user_agent TEXT,
       type TEXT
);


CREATE TABLE table_comments (
       table_name  VARCHAR(255),
       comment_text TEXT
);

CREATE TABLE column_comments (
       table_name  VARCHAR(255),
       column_name VARCHAR(255),
       comment_text TEXT
);

CREATE TABLE monthly_archive (
       monthly_archive_id INTEGER PRIMARY KEY AUTOINCREMENT,
       "site_id" VARCHAR(16) NOT NULL REFERENCES site(id)
                           ON DELETE CASCADE ON UPDATE CASCADE,
       "month" INTEGER(2) NOT NULL,
       "year"  INTEGER(4) NOT NULL
);

CREATE UNIQUE INDEX unique_site_month ON monthly_archive ("site_id", "month", "year");

CREATE TABLE text_month (
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       monthly_archive_id INTEGER NOT NULL REFERENCES monthly_archive(monthly_archive_id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       PRIMARY KEY (title_id, monthly_archive_id)
);

CREATE TABLE legacy_link (
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       legacy_path VARCHAR(255) NOT NULL,
       new_path VARCHAR(255) NOT NULL,
       PRIMARY KEY (site_id, legacy_path)
);

CREATE TABLE muse_header (
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       muse_header VARCHAR(255) NOT NULL,
       muse_value TEXT,
       PRIMARY KEY (title_id, muse_header)
);

CREATE TABLE amw_session (
       session_id VARCHAR(255) NOT NULL,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       expires INTEGER NULL,
       session_data BLOB NULL,
       flash_data BLOB NULL,
       generic_data BLOB NULL,
       PRIMARY KEY (site_id, session_id)
);

CREATE TABLE node (
       node_id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       uri VARCHAR(255) NOT NULL,
       sorting_pos INTEGER NOT NULL DEFAULT 0,
       full_path TEXT,
       parent_node_id INTEGER NULL REFERENCES node(node_id)
       ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE UNIQUE INDEX unique_node_site_id_uri ON node("site_id", "uri");

CREATE TABLE node_body (
       node_id INTEGER NOT NULL REFERENCES node(node_id) ON DELETE CASCADE ON UPDATE CASCADE,
       lang VARCHAR(3) NOT NULL DEFAULT 'en',
       title_muse TEXT,
       title_html TEXT,
       body_muse TEXT,
       body_html TEXT,
       PRIMARY KEY(node_id, lang)
);

CREATE UNIQUE INDEX unique_node_id_lang ON node_body("node_id", "lang");

CREATE TABLE node_title (
        node_id   INTEGER NOT NULL REFERENCES node(node_id)
                 ON DELETE CASCADE ON UPDATE CASCADE,
        title_id INTEGER NOT NULL REFERENCES title(id)
                 ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (node_id, title_id)
);

CREATE TABLE node_category (
       node_id      INTEGER NOT NULL REFERENCES node(node_id)
                   ON DELETE CASCADE ON UPDATE CASCADE,
       category_id INTEGER NOT NULL REFERENCES category(id)
                   ON DELETE CASCADE ON UPDATE CASCADE,
       PRIMARY KEY (node_id, category_id)
);

CREATE TABLE title_attachment (
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       attachment_id INTEGER NOT NULL REFERENCES attachment(id)
               ON DELETE CASCADE ON UPDATE CASCADE,
       PRIMARY KEY (title_id, attachment_id)
);

CREATE TABLE whitelist_ip (
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       ip VARCHAR(64),
       user_editable SMALLINT NOT NULL DEFAULT 0,
       PRIMARY KEY (site_id, ip)
);

CREATE TABLE include_path (
       include_path_id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       directory TEXT,
       sorting_pos INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE included_file (
       included_file_id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                    ON DELETE CASCADE ON UPDATE CASCADE,
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       file_path TEXT NOT NULL,
       file_timestamp DATETIME,
       file_epoch INTEGER
);

INSERT INTO table_comments (table_name, comment_text)
       values
         ('vhost', 'Virtual hosts definitions'),
         ('table_comments', 'Table comments, used internally'),
         ('column_comments', 'Column comments, used internally'),
         ('site', 'Site definitions'),
         ('site_options', 'Site options'),
         ('users', 'User definitions'),
         ('roles', 'Role definitions'),
         ('user_site', 'Linking table between users and sites'),
         ('user_role', 'Linking table between users and roles'),
         ('revision', 'Text revisions'),
         ('job', 'Queue for jobs'),
         ('bulk_job', 'Aggregated jobs'),
         ('job_file', 'Files produced by a job'),
         ('title', 'Texts metadata'),
         ('redirection', 'Redirections'),
         ('title_category', 'Linking table between texts and categories'),
         ('category', 'Text categories'),
         ('category_description', 'Category descriptions'),
         ('attachment', 'Attachment to texts'),
         ('site_link', 'Site links'),
         ('text_month', 'Linking table between texts and monthly archives'),
         ('monthly_archive', 'Monthly archives'),
         ('legacy_link', 'Handle old paths for migrated sites'),
         ('bookbuilder_profile', 'Bookbuilder profiles'),
         ('bookbuilder_session', 'Bookbuilder sessions'),
         ('custom_formats', 'Custom output formats'),
         ('muse_header', 'Raw title headers'),
         ('text_internal_link', 'Internal links found in the body'),
         ('text_part', 'Text sectioning'),
         ('global_site_files', 'Files which site uses'),
         ('amw_session', 'Session backend'),
         ('title_stat', 'Usage statistics'),
         ('title_attachment', 'Linking table from Title to Attachment'),
         ('whitelist_ip', 'IP whitelisting for access to private sites'),
         ('node', 'Nestable nodes'),
         ('node_body', 'Nodes description'),
         ('node_title', 'Linking table from Node to Title'),
         ('node_category', 'Linking table from Node to Category'),
         ('included_file', 'Files included in muse documents'),
         ('include_path', 'Directories to search for file inclusions')
         ;

