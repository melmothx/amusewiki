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
       mode VARCHAR(16) NOT NULL DEFAULT 'blog',
       locale VARCHAR(3) NOT NULL DEFAULT 'en',

       -- TODO: move these things in a setting table, it's too cluttered
       magic_question VARCHAR(255) NOT NULL DEFAULT '',
       magic_answer   VARCHAR(255) NOT NULL DEFAULT '',

       -- list of space separated category codes, if you want this feature
       fixed_category_list VARCHAR(255),

       -- canonical url for RSS and other things
       sitename VARCHAR(255) NOT NULL DEFAULT '',
       siteslogan VARCHAR(255) NOT NULL DEFAULT '',
       theme VARCHAR(32) NOT NULL DEFAULT '',
       logo VARCHAR(255), -- could be a path, so keep it at 255
       mail_notify VARCHAR(255),
       mail_from   VARCHAR(255),
       canonical VARCHAR(255) NOT NULL DEFAULT '',

       sitegroup VARCHAR(255) NOT NULL DEFAULT '',

       -- labels
       sitegroup_label VARCHAR(255),
       catalog_label VARCHAR(255),
       specials_label VARCHAR(255),

       -- boolean for multilanguage
       multilanguage VARCHAR(255) NOT NULL DEFAULT '',

       -- book builder page limit
       bb_page_limit INTEGER NOT NULL DEFAULT 1000,
       -- formats
       tex       INTEGER(1) NOT NULL DEFAULT 1,
       pdf       INTEGER(1) NOT NULL DEFAULT 1,
       a4_pdf    INTEGER(1) NOT NULL DEFAULT 1,
       lt_pdf    INTEGER(1) NOT NULL DEFAULT 1,
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
       mainfont VARCHAR(255) NOT NULL DEFAULT 'Linux Libertine O',
       nocoverpage INTEGER(1) NOT NULL DEFAULT 0,
       logo_with_sitename INTEGER(1) NOT NULL DEFAULT 0,
       twoside INTEGER(1) NOT NULL DEFAULT 0
);

CREATE TABLE users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       username VARCHAR(255) NOT NULL,
       password VARCHAR(255) NOT NULL,
       email    VARCHAR(255),
       active   INTEGER(1) NOT NULL DEFAULT 1
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
       errors    TEXT
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

