PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS vhost;
DROP TABLE IF EXISTS site;
DROP TABLE IF EXISTS title_author;
DROP TABLE IF EXISTS title;
DROP TABLE IF EXISTS author;

CREATE TABLE vhost (
       name VARCHAR(255) PRIMARY KEY,
       site_id VARCHAR(8) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE site (
       id VARCHAR(8) PRIMARY KEY,
       mode VARCHAR(16) NOT NULL DEFAULT 'blog',
       locale VARCHAR(3) NOT NULL DEFAULT 'en',

       -- TODO: move these things in a setting table, it's too cluttered
       magic_question TEXT NOT NULL DEFAULT 'The first month of the year...',
       magic_answer   TEXT NOT NULL DEFAULT 'January',

       -- list of space separated category codes, if you want this feature
       fixed_category_list TEXT,

       -- canonical url for RSS and other things
       sitename VARCHAR(255) NOT NULL DEFAULT '',
       siteslogan VARCHAR(255) NOT NULL DEFAULT '',
       theme VARCHAR(32) NOT NULL DEFAULT '',
       logo VARCHAR(32),
       mail VARCHAR(128),
       canonical VARCHAR(255) NOT NULL DEFAULT '',

       -- book builder page limit
       bb_page_limit INTEGER NOT NULL DEFAULT 1000,
       -- formats
       tex       INTEGER NOT NULL DEFAULT 1,
       pdf       INTEGER NOT NULL DEFAULT 1,
       a4_pdf    INTEGER NOT NULL DEFAULT 1,
       lt_pdf    INTEGER NOT NULL DEFAULT 1,
       html      INTEGER NOT NULL DEFAULT 1,
       bare_html INTEGER NOT NULL DEFAULT 1,
       epub      INTEGER NOT NULL DEFAULT 1,
       zip       INTEGER NOT NULL DEFAULT 1,
       ttdir     VARCHAR(1024) NOT NULL DEFAULT '',
       -- tex options
       papersize VARCHAR(64) NOT NULL DEFAULT '', -- will pick the generic
       division INTEGER NOT NULL DEFAULT '12',
       bcor VARCHAR(16) NOT NULL DEFAULT '0mm',
       fontsize INTEGER NOT NULL DEFAULT '10',
       mainfont VARCHAR(255) NOT NULL DEFAULT 'Linux Libertine O',
       twoside INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       username VARCHAR(32) NOT NULL,
       password VARCHAR(255) NOT NULL,
       email    VARCHAR(255),
       active   INTEGER NOT NULL DEFAULT 0,
       site_id VARCHAR(8) REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE roles (
       id INTEGER PRIMARY KEY,
       role VARCHAR(255) UNIQUE
);

CREATE TABLE user_role (
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
        role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (user_id, role_id)
);


CREATE TABLE revision (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       site_id VARCHAR(8) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       title_id INTEGER NOT NULL REFERENCES title(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       f_full_path_name TEXT,
       status VARCHAR(16) NOT NULL DEFAULT 'editing',
       user_id INTEGER NOT NULL DEFAULT 0, -- will reference the user
       session_id VARCHAR(255), -- can be null or false
       updated DATETIME NOT NULL -- internal
);

CREATE TABLE page (
       id INTEGER PRIMARY KEY,
       site_id VARCHAR(8) NOT NULL REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE,
       pubdate DATETIME NOT NULL,
       created DATETIME NOT NULL, -- internal
       updated DATETIME NOT NULL, -- internal
       user_id INTEGER NOT NULL DEFAULT 0, -- will reference the user
       uri VARCHAR(255),
       title VARCHAR(255), -- the title
       html_body TEXT, -- the body itself
       f_path TEXT NOT NULL,
       status VARCHAR(16) NOT NULL DEFAULT 'published'
);
CREATE UNIQUE INDEX unique_page ON page (uri, site_id);

CREATE TABLE job (
       id INTEGER PRIMARY KEY,
       site_id VARCHAR(8) NOT NULL REFERENCES site(id)
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
        uid         VARCHAR(255),
        -- to attach files
        attach      VARCHAR(255),
        -- to overwrite the timestamp
        pubdate     DATETIME NOT NULL,
        status      VARCHAR(16) NOT NULL DEFAULT 'unpublished',

        -- from the scanner
        f_path      TEXT NOT NULL,
        f_name      VARCHAR(255) NOT NULL,
        f_archive_rel_path VARCHAR(4) NOT NULL,
        f_timestamp DATETIME NOT NULL,
        f_full_path_name TEXT NOT NULL,
        f_suffix    VARCHAR(16) NOT NULL,

        uri         VARCHAR(255) NOT NULL,
        deleted     TEXT NOT NULL DEFAULT '',

        sorting_pos INTEGER NOT NULL DEFAULT 0,
        site_id     VARCHAR(8) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_text ON title (uri, site_id);


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
        site_id VARCHAR(8) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_category ON category (uri, site_id, type);

CREATE TABLE attachment (
       id INTEGER PRIMARY KEY,
       f_path      TEXT NOT NULL,
       f_name      VARCHAR(255) NOT NULL,
       f_archive_rel_path VARCHAR(4) NOT NULL,
       f_timestamp DATETIME NOT NULL,
       f_full_path_name TEXT NOT NULL,
       f_suffix    VARCHAR(16) NOT NULL,
       uri   VARCHAR(255) NOT NULL,
       site_id VARCHAR(8) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX unique_attachment ON attachment (uri, site_id);

INSERT INTO site (id, locale, mode,
                  sitename, siteslogan, theme, bb_page_limit,
                  logo, canonical,
                  a4_pdf, lt_pdf,
                  papersize, division, bcor, fontsize, mainfont, twoside
                  )
       VALUES (
              '0blog0', 'hr', 'modwiki',
              'hrvatski blog', 'samo test', '', 5,
              'logo-yu',
              'http://blog.amusewiki.org',
              1, 1,
              'a4', 9, '1cm', 12, 'Charis SIL', 1
              ),
              (
              '0test0', 'en', 'blog',
              'english test', 'only a test', 'test-theme', 10,
              'logo-en',
              'http://test.amusewiki.org',
              0, 0,
              '', 12, '0mm', 10, '', 1
              ),
              ('0wiki0', 'en', 'openwiki',
              'a wiki', 'a wiki', '', 5,
              'logo-en',
              'http://wiki.amusewiki.org',
              0, 0,
              '', 12, '0mm', 10, '', 1
              ),
              (
              '0empty0', 'en', 'blog',
              '', '', '', 10,
              '',
              'http://empty.amusewiki.org',
              1, 1,
              '', 12, '', '', '', 1
              );

UPDATE site SET magic_question = 'First month of the year';
UPDATE site SET magic_answer = 'January';

INSERT INTO vhost VALUES ('blog.amusewiki.org', '0blog0');
INSERT INTO vhost VALUES ('test.amusewiki.org', '0test0');
INSERT INTO vhost VALUES ('empty.amusewiki.org', '0empty0');
INSERT INTO vhost VALUES ('wiki.amusewiki.org', '0wiki0');

INSERT INTO roles VALUES (1, 'root');
INSERT INTO roles VALUES (2, 'librarian');

INSERT INTO users VALUES (1, 'root', 'root', '', 1, NULL);
INSERT INTO users VALUES (2, 'user1', 'pass', '', 1, '0blog0');
INSERT INTO users VALUES (3, 'user2', 'pass', '', 1, '0blog0');
INSERT INTO users VALUES (4, 'user3', 'pass', '', 0, '0blog0');

INSERT INTO user_role VALUES (1, 1),
                             (2, 2),
                             (3, 2),
                             (4, 2);

