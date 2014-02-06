PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS vhost;
DROP TABLE IF EXISTS site;
DROP TABLE IF EXISTS title_author;
DROP TABLE IF EXISTS title;
DROP TABLE IF EXISTS author;

CREATE TABLE vhost (
       name VARCHAR(255) PRIMARY KEY,
       site_id VARCHAR(8) REFERENCES site(id)
                          ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE site (
       id VARCHAR(8) PRIMARY KEY,
       locale VARCHAR(3) NOT NULL DEFAULT 'en'
);

CREATE TABLE title (
        id          INTEGER PRIMARY KEY,

        -- from the .muse file
        title       TEXT NOT NULL DEFAULT '',
        subtitle    TEXT NOT NULL DEFAULT '',

        -- 3 letters, as per doc
        lang        VARCHAR(3) NOT NULL DEFAULT 'en',

        date        TEXT,
        notes       TEXT NOT NULL DEFAULT '',
        source      TEXT NOT NULL DEFAULT '',

        -- sorting only, as per doc
        list_title  TEXT,

        -- display only, as per doc
        author      TEXT,

        -- from tabula rasa
        -- to identify translations texts across libraries
        uid         VARCHAR(255),
        -- to attach files
        attach      VARCHAR(255),
        -- to overwrite the timestamp
        pubdate     TIMESTAMP,

        -- from the scanner
        f_path      TEXT NOT NULL,
        f_name      VARCHAR(255) NOT NULL,
        f_archive_rel_path VARCHAR(4) NOT NULL,
        f_timestamp VARCHAR(255) NOT NULL,
        f_full_path_name TEXT NOT NULL,
        f_suffix    VARCHAR(16) NOT NULL,

        uri         VARCHAR(255) NOT NULL,
        deleted     TEXT NOT NULL DEFAULT '',
        site_id     VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_text ON title (uri, site_id);


-- 'book_author' is a many-to-many join table between books & authors
CREATE TABLE title_category (
        title_id     INTEGER REFERENCES title(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        category_id  INTEGER REFERENCES category(id)
                     ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (title_id, category_id)
);
CREATE TABLE category (
        id          INTEGER PRIMARY KEY,
        name  TEXT,
        uri   VARCHAR(255) NOT NULL,
        type  VARCHAR(16) NOT NULL,
        site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX unique_category ON category (uri, site_id, type);

CREATE TABLE attachment (
       id INTEGER PRIMARY KEY,
       f_path      TEXT NOT NULL,
       f_name      VARCHAR(255) NOT NULL,
       f_archive_rel_path VARCHAR(4) NOT NULL,
       f_timestamp VARCHAR(255) NOT NULL,
       f_full_path_name TEXT NOT NULL,
       f_suffix    VARCHAR(16) NOT NULL,
       uri   VARCHAR(255) NOT NULL,
       site_id VARCHAR(16) NOT NULL REFERENCES site(id)
                                ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX unique_attachment ON attachment (uri, site_id);

INSERT INTO site VALUES ('blog', 'hr');
INSERT INTO site VALUES ('test', 'en');
INSERT INTO site VALUES ('empty', 'en');

INSERT INTO vhost VALUES ('blog.amusewiki.org', 'blog');
INSERT INTO vhost VALUES ('test.amusewiki.org', 'test');
INSERT INTO vhost VALUES ('empty.amusewiki.org', 'empty');

