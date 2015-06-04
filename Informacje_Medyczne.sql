CREATE TABLE osoby(
id int primary key,
imie varchar(50) not null,
nazwisko varchar(50) not null
pesel char(11)
);
CREATE TABLE lekarze(
id int primary key
id_osoby int references osoby(id)
);
CREATE TABLE specjalizacje(
id int primary key,
id_lekarza int references lekarze(id)
);
CREATE TABLE uslugodawcy(
id int primary key,
nazwa varchar(150) not null,
adres varchar(150) not null
);
CREATE TABLE uslugi(
id int primary key,
id_lekarza references lekarze(id),
id_osoby references osoby(id),
id_uslugodawcy references uslugodawcy(id)
);
CREATE TABLE recepty(
id int primary key,
id_lekarza references lekarze(id),
id_osoby references osoby(id)
);
CREATE TABLE apteki(
id int primary key,
nazwa varchar(150) not null,
adres varchar(150) not null,
id_oddzialu references oddzialy(id)
);
CREATE TABLE oddzialy(
id int primary key,
nazwa varchar(150) not null,
adres varchar(150) not null
);
CREATE TABLE umowy(
id int primary key,
id_oddzialu references oddzialy(id),
id_uslugodawcy references uslugodawcy(id),
data_od date not null,
data_do date not null,
CONSTRAINT daty data_od<=data_do
);
