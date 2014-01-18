PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS site;
DROP TABLE IF EXISTS title_author;
DROP TABLE IF EXISTS title;
DROP TABLE IF EXISTS author;


CREATE TABLE site (
       name VARCHAR(255) PRIMARY KEY,
       id VARCHAR(16) NOT NULL DEFAULT 'default'
);

CREATE TABLE title (
        id          INTEGER PRIMARY KEY,
        title       TEXT,
        uri         TEXT,
        site_id     VARCHAR(16)
);

-- 'book_author' is a many-to-many join table between books & authors
CREATE TABLE title_author (
        title_id     INTEGER REFERENCES title(id) ON DELETE CASCADE ON UPDATE CASCADE,
        author_id   INTEGER REFERENCES author(id) ON DELETE CASCADE ON UPDATE CASCADE,
        PRIMARY KEY (title_id, title_id)
);
CREATE TABLE author (
        id          INTEGER PRIMARY KEY,
        name  TEXT,
        uri   TEXT,
        site_id VARCHAR(16)
);


INSERT INTO site VALUES ('en.anarhija.net:3000', 'en');
INSERT INTO site VALUES ('fi.anarhija.net:3000', 'fi');
INSERT INTO site VALUES ('mk.anarhija.net:3000', 'mk');
INSERT INTO site VALUES ('sh.anarhija.net:3000', 'yu');
INSERT INTO site VALUES ('hr.anarhija.net:3000', 'yu');
INSERT INTO site VALUES ('sr.anarhija.net:3000', 'yu');
INSERT INTO site VALUES ('ba.anarhija.net:3000', 'yu');
INSERT INTO site VALUES ('yu.anarhija.net', 'yu');
INSERT INTO site VALUES ('en.anarhija.net', 'en');
INSERT INTO site VALUES ('fi.anarhija.net', 'fi');
INSERT INTO site VALUES ('mk.anarhija.net', 'mk');
INSERT INTO site VALUES ('sh.anarhija.net', 'yu');
INSERT INTO site VALUES ('hr.anarhija.net', 'yu');
INSERT INTO site VALUES ('sr.anarhija.net', 'yu');
INSERT INTO site VALUES ('ba.anarhija.net', 'yu');


INSERT INTO title VALUES (1, 'Kaliban i veštica',
        'silvia-federici-kaliban-i-vestica', 'yu');
INSERT INTO title VALUES (2, 'Dadaland',
       'jean-arp-dadaland', 'yu');

INSERT INTO author VALUES (1, 'Silvia Federici', 'silvia-federici', 'yu');
INSERT INTO author VALUES (2, 'Jean Arp', 'jean-arp', 'yu');

INSERT INTO title_author VALUES (1, 1);
INSERT INTO title_author VALUES (2, 2);

