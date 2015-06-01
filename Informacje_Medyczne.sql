CREATE TABLE osoby(
id int primary key,
imie varchar(50) not null,
nazwisko varchar(50) not null
pesel char(11) not null
);
CREATE TABLE lekarze(
id int primary key
id_osoby int references osoby(id)
);
CREATE TABLE specjalizacje(
id int primary key,
id_lekarza int references lekarze(id)
);
