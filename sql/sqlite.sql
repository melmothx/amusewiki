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
       fixed_category_list VARCHAR(255),

       sitename VARCHAR(255) NOT NULL DEFAULT '',
       siteslogan VARCHAR(255) NOT NULL DEFAULT '',
       theme VARCHAR(32) NOT NULL DEFAULT '',
       logo VARCHAR(255) NOT NULL DEFAULT '', -- could be a path, so keep it at 255
       mail_notify VARCHAR(255),
       mail_from   VARCHAR(255),

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

CREATE TABLE job (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       task      VARCHAR(32),
       payload   TEXT, -- the JSON stuff
       status    VARCHAR(32),
       created   DATETIME NOT NULL,
       completed DATETIME,
       priority  INTEGER,
       produced  VARCHAR(255),
       username  VARCHAR(255),
       errors    TEXT
);

CREATE TABLE job_file (
       filename VARCHAR(255) NOT NULL PRIMARY KEY,
       slot VARCHAR(255) NOT NULL DEFAULT '',
       job_id INTEGER NOT NULL REFERENCES job(id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE title (
        id          INTEGER PRIMARY KEY,

        -- from the .muse file
        title       TEXT NOT NULL DEFAULT '',
        subtitle    TEXT NOT NULL DEFAULT '',

        -- 3 letters, as per doc
        lang        VARCHAR(3) NOT NULL DEFAULT 'en',

        date        TEXT NOT NULL DEFAULT '',
        notes       TEXT NOT NULL DEFAULT '',
        source      TEXT NOT NULL DEFAULT '',

        -- sorting only, as per doc
        list_title  TEXT NOT NULL DEFAULT '',

        -- display only, as per doc
        author      TEXT NOT NULL DEFAULT '',

        -- from tabula rasa
        -- to identify translations texts across libraries
        uid         VARCHAR(255) NOT NULL DEFAULT '',
        -- to attach files
        attach      TEXT,
        -- to overwrite the timestamp
        pubdate     DATETIME NOT NULL,
        status      VARCHAR(16) NOT NULL DEFAULT 'unpublished',

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
        deleted     TEXT NOT NULL DEFAULT '',

        slides      INTEGER(1) NOT NULL DEFAULT 0,

        text_structure TEXT NOT NULL DEFAULT '',

        cover VARCHAR(255) NOT NULL DEFAULT '',
        teaser TEXT NOT NULL DEFAULT '',

        sorting_pos INTEGER NOT NULL DEFAULT 0,
        site_id     VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_text ON title (uri, f_class, site_id);

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
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX unique_attachment ON attachment (uri, site_id);

CREATE TABLE site_link (
       url VARCHAR(255) NOT NULL,
       label VARCHAR(255) NOT NULL,
       sorting_pos INTEGER NOT NULL DEFAULT 0,
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
         ('title_stat', 'Usage statistics');
