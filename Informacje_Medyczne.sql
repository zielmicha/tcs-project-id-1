begin;

create table osoby (
       id serial primary key,
       imie varchar(150) not null,
       nazwisko varchar(150) not null,
       pesel char(11)
);

create table lekarze (
       id serial primary key,
       id_osoby serial references osoby(id)
);

create table specjalizacje (
       id serial primary key,
       id_lekarza serial references lekarze(id),
       specjalizacja varchar(150) not null
);

create table uslugodawcy (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null
);

create table typy_uslug (
       id serial primary key,
       nazwa varchar,
       koszt numeric(9, 2),
       obowiazuje tsrange not null
);

create table uslugi (
       id serial primary key,
       id_lekarza serial references lekarze(id),
       id_osoby serial references osoby(id) not null,
       id_uslugodawcy serial references uslugodawcy(id) not null,
       typ serial references typy_uslug(id) not null,
       opis text
);

create table oddzialy (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null
);

create table apteki (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null,
       id_oddzialu serial references oddzialy(id) not null
);

create table recepty (
       id serial primary key,
       id_lekarza serial references lekarze(id) not null,
       id_osoby serial references osoby(id) not null,
       id_apteki serial references apteki(id)
);

create table leki (
       id serial primary key,
       nazwa text,
       koszt numeric(9, 2),
       okres tsrange
);


create table choroby(
      id serial primary key,
      nazwa varchar
);

create table recepta_lek (
       id_recepty serial references recepty(id),
       id_leku serial references leki(id),
       refundacja int check (refundacja between 0 and 100),
       zrealizowano int,
       choroba serial references choroby(id),
       ilosc int

);

create table zgloszenie (
       id serial primary key,
       id_osoby serial references osoby(id),
       id_oddzialu serial references oddzialy(id),
       okres tsrange not null
);

create table umowy (
       id serial primary key,
       id_oddzialu serial references oddzialy(id),
       id_uslugodawcy serial references uslugodawcy(id),
       okres tsrange not null
);


create function czy_ma_umowe(placowka bigint, kiedy timestamp) returns bool as $$
       select count(*) > 0
              from umowy where id_uslugodawcy = placowka
                               and okres @> kiedy;
$$ language sql;

create function czy_ubezpieczony(czlowiek bigint, kiedy timestamp) returns bool as $$
       select count(*) > 0
              from zgloszenie where id_osoby = czlowiek
                                and okres @> kiedy;
$$ language sql;



create view lekarze_dane as select lekarze.id, osoby.imie, osoby.nazwisko, osoby.pesel
      from lekarze 
            left join osoby on lekarze.id = osoby.id; 

create view recepty_koszt as select recepty.id, recepty.id_osoby,
       sum(koszt * ilosc)
       from recepty
            left join recepta_lek on id_recepty = recepty.id
            join leki on id_leku = leki.id
            group by recepty.id;

create function pesel_trigger() returns trigger AS $$
declare
   a int[];
   cyfra int;
begin

   if char_length(new.pesel) != 11 then
      raise exception 'Niepoprawny PESEL';
   end if;
   a := regexp_split_to_array(new.pesel, '')::int[];
   cyfra := 1*a[1] + 3*a[2] + 7*a[3] + 9*a[4] + 1*a[5] + 3*a[6] + 7*a[7] + 9*a[8]
    + 1*a[9] + 3*a[10] + a[11];
   if cyfra % 10 != 0 then
      raise exception 'Niepoprawny PESEL';
   end if;

   return new;
end;
$$ language plpgsql;

create trigger pesel_check before insert or update on osoby
for each row execute procedure pesel_trigger();

end;

