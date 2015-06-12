begin;

create table osoby (
       id serial primary key,
       imie varchar(150) not null,
       nazwisko varchar(150) not null,
       pesel char(11)
);


create table uslugodawcy (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null
);
create table lekarze (
       id serial primary key,
       id_osoby serial references osoby(id)
);



create table zatrudnieni (
		id serial primary key,
    miejsce_pracy serial references uslugodawcy (id),
    id_lekarza serial references lekarze (id),
		stanowisko varchar(150)
);



create table specjalizacje (
       id serial primary key,
       id_lekarza serial references lekarze(id),
       specjalizacja varchar(150) not null
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
       id_apteki serial references apteki(id),
       data_wystawienia timestamp
);

create table leki (
       id serial primary key,
       nazwa text,
       koszt numeric(9, 2)
       
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
       ilosc int,
       okres tsrange

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

create table historia_chorob (
		id serial primary key,
		id_osoby serial references osoby(id),
		id_chroby serial references choroby(id),
)

create function czy_ubezpieczony(czlowiek int, kiedy timestamp default now()) returns bool as $$
       select count(*) > 0
              from zgloszenie where id_osoby = czlowiek
                                and okres @> kiedy;
                                
                 
$$ language sql;

	

<<<<<<< HEAD
create view ubezpieczenia_pracownicy as select osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel
			CASE WHEN czy_ubezpieczony(lekarze.id_osoby, current_timestamp) THEN 'UBEZPIECZONY' ELSE 'BRAK UBEZPIECZENIA' END
			from zatrudnieni
				left join osoby on (zatrudnieni.id_osoby = osoby.id)
				order by osoby.nazwisko;


=======
create view ubezpieczenia_pracownicy as select lekarze.id, osoby.imie, osoby.nazwisko, osoby.pesel,
			CASE WHEN czy_ubezpieczony(osoby.id) THEN 'UBEZPIECZONY' ELSE 'BRAK UBEZPIECZENIA' end
			from zatrudnieni
				left join osoby on (zatrudnieni.id = osoby.id)
				order by osoby.nazwisko;  
>>>>>>> d308ab340db48b588964b1b2e8c98e6b274c2d52

 

create function czy_ma_umowe(placowka bigint, kiedy timestamp) returns bool as $$
       select count(*) > 0
              from umowy where id_uslugodawcy = placowka
                               and okres @> kiedy;
$$ language sql;



<<<<<<< HEAD
create view lekarze_dane as select lekarze.id, osoby.imie, osoby.nazwisko, osoby.pesel, specjalizacje.specjalizacja
      from lekarze 
            left join osoby on lekarze.id_osoby = osoby.id
            left join specjalizacje on lekarze.id = specjalizacje.id_lekarza
=======
create view lekarze_dane as select lekarze.id, osoby.imie, osoby.nazwisko, osoby.pesel, zatrudnieni.miejsce_pracy, zatrudnieni.stanowisko
      from lekarze 
            left join osoby on lekarze.id = osoby.id
            left join zatrudnieni on lekarze.id = zatrudnieni.id_lekarza
>>>>>>> d308ab340db48b588964b1b2e8c98e6b274c2d52
            order by osoby.nazwisko; 

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

