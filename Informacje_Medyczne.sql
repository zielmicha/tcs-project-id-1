CREATE TABLE osoby(
id int primary key,
imie varchar(150) not null,
nazwisko varchar(150) not null
pesel char(11)
);
CREATE TABLE lekarze(
id int primary key
id_osoby int references osoby(id)
);
CREATE TABLE specjalizacje(
id int primary key,
id_lekarza int references lekarze(id),
specjalizacja varchar(150) not null
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
CREATE OR REPLACE FUNCTION check_pesel() RETURNS trigger AS $check_pesel$
DECLARE
b integer;
BEGIN
IF char_length(NEW.pesel)!=11 then
      RAISE EXCEPTION 'Niepoprawny PESEL';
END IF;
b=(ascii(substring(NEW.pesel from 1 for 1))-48)+3*(ascii(substring(NEW.pesel from 2 for 1))-48)+7*(ascii(substring(NEW.pesel from 3 for 1))-48)+9*(ascii(substring(NEW.pesel from 4 for 1))-48)+(ascii(substring(NEW.pesel from 5 for 1))-48)+3*(ascii(substring(NEW.pesel from 6 for 1))-48)+7*(ascii(substring(NEW.pesel from 7 for 1))-48)+9*(ascii(substring(NEW.pesel from 8 for 1))-48)+(ascii(substring(NEW.pesel from 9 for 1))-48)+3*(ascii(substring(NEW.pesel from 10 for 1))-48);
b=b%10;
b=(10-b)%10;
IF b!=(ascii(substring(NEW.pesel from 11 for 1))-48) then
RAISE EXCEPTION 'Niepoprawny PESEL';
END IF;
RETURN NEW;
END;
$check_pesel$ LANGUAGE plpgsql;
CREATE TRIGGER check_pesel BEFORE INSERT OR UPDATE ON osoby
FOR EACH ROW EXECUTE PROCEDURE check_pesel();
