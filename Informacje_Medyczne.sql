begin;

create table osoby (
       id serial primary key,
       imie varchar(150) not null,
       nazwisko varchar(150) not null,
       urodzony date check( urodzony <= CURRENT_DATE),
       plec varchar(150) check(plec = 'kobieta' or plec = 'mezczyzna') not null, 
       pesel char(11) 
);

create table uslugodawcy (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null
);
create table lekarze (
       id serial primary key,
       id_osoby serial references osoby(id) not null
);

create table zatrudnieni (
		id serial primary key,
    miejsce_pracy serial references uslugodawcy (id),
    id_lekarza serial references lekarze (id),
		stanowisko varchar(150) not null
);

create table specjalizacje (
       id serial primary key,
       id_lekarza serial references lekarze(id) not null,
       specjalizacja varchar(150) not null
);

create table typy_uslug (
       id serial primary key,
       nazwa varchar not null,
       koszt numeric(9, 2),
       obowiazuje tsrange not null
);

create table uslugi (
       id serial primary key,
       id_lekarza serial references lekarze(id) not null,
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
       data_wystawienia timestamp not null
);

create table leki (
       id serial primary key,
       nazwa varchar(150) not null,
       koszt numeric(9, 2)
       
);


create table choroby (
      id serial primary key,
      nazwa varchar(150) not null
);

create table recepta_lek (
       id_recepty serial references recepty(id) not null,
       id_leku serial references leki(id) not null,
       refundacja int default 0 check (refundacja between 0 and 100),
       zrealizowano int default 0,
       choroba serial references choroby(id),
       ilosc int,
       okres tsrange

);

create table zgloszenie (
       id serial primary key,
       id_osoby serial references osoby(id) not null,
       id_oddzialu serial references oddzialy(id) not null,
       okres tsrange not null
);

create table umowy (
       id serial primary key,
       id_oddzialu serial references oddzialy(id) not null,
       id_uslugodawcy serial references uslugodawcy(id) not null,
       okres tsrange not null
);

create table historia_chorob (
		id serial primary key,
		id_osoby serial references osoby(id) not null,
		id_chroby serial references choroby(id) not null
);

create function czy_ubezpieczony (czlowiek int, kiedy timestamp default now()) returns bool as $$
       select count(*) > 0
              from zgloszenie where id_osoby = czlowiek
                                and okres @> kiedy;
                                
                 
$$ language sql;

	

create view ubezpieczenia_pracownicy as select osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel,
			CASE WHEN czy_ubezpieczony(lekarze.id_osoby) THEN 'UBEZPIECZONY' ELSE 'BRAK UBEZPIECZENIA' END
			from zatrudnieni
				left join lekarze on zatrudnieni.id_lekarza = lekarze.id
        join osoby on lekarze.id_osoby = osoby.id
				order by osoby.nazwisko;


 

create function czy_ma_umowe (placowka bigint, kiedy timestamp) returns bool as $$
       select count(*) > 0
              from umowy where id_uslugodawcy = placowka
                               and okres @> kiedy;
$$ language sql;

create view uslugodawcy_uslugi as select 
    uslugodawcy.id, uslugodawcy.nazwa, uslugi.id as "id usługi",
    typy_uslug.nazwa as "nazwa usługi"
      from uslugodawcy 
            join uslugi on uslugodawcy.id = uslugi.id_uslugodawcy
            join typy_uslug on typy_uslug.id = uslugi.typ
            order by 1, 3; 


create view lekarze_dane as select lekarze.id, osoby.imie, osoby.nazwisko, osoby.pesel, zatrudnieni.miejsce_pracy, zatrudnieni.stanowisko
      from lekarze 
            left join osoby on lekarze.id = osoby.id
            left join zatrudnieni on lekarze.id = zatrudnieni.id_lekarza
            order by osoby.nazwisko; 

create view lekarze_specjalizacje as SELECT s.id,  array_agg(g.specjalizacja) as specjalizacja        
      FROM lekarze s
        LEFT JOIN specjalizacje g ON g.id_lekarza = s.id
        GROUP BY s.id
        order by 1;


create view recepty_koszt as select recepty.id, recepty.id_osoby,
       sum(koszt * ilosc)
       from recepty
            left join recepta_lek on id_recepty = recepty.id
            join leki on id_leku = leki.id
            group by recepty.id;

create view recepty_refundacja as select recepty.id, recepty.id_osoby,
       sum( (koszt * ilosc * refundacja)::numeric / 100  ) as "refundacja"
       from recepty
            left join recepta_lek on id_recepty = recepty.id
            join leki on id_leku = leki.id
            group by recepty.id;

create view lekarze_leki as select osoby.imie, osoby.nazwisko, lekarze.id, 
recepty.id_osoby as "pacjent", recepty.id as "id recepty", 
recepty.data_wystawienia as "data",leki.nazwa, recepta_lek.zrealizowano
  
       from lekarze
            join osoby on osoby.id = lekarze.id_osoby
            join recepty on lekarze.id = recepty.id_lekarza
            join recepta_lek on id_recepty = recepty.id
            join leki on recepta_lek.id_leku =  leki.id
            order by 2, 1, lekarze.id;




create function pesel_trigger() returns trigger AS $$
declare
   a int[];
   cyfra int;
   day int;
   year int;
   month int;
   yearspec int;
begin

   if char_length(new.pesel) != 11 then
      raise exception 'Niepoprawny PESEL';
   end if;
   a := regexp_split_to_array(new.pesel, '')::int[];
   if new.plec = 'kobieta' then
      if a[10]%2 = 1 then
          raise exception 'Niepoprawny PESEL';
      end if;
    else if a[10]%2 = 0 then
          raise exception 'Niepoprawny PESEL';
         end if;
    end if;
    day := 10 * a[4] + a[5];
    yearspec := (10 * a[2] + a[3])/20;
    month := (10 * a[2] + a[3])%20;
    year := 10 * a[1] + a[4];
    case yearspec 
          when 0 then 
              year := 1900 + year;
          when 1 then 
              year := 2000 + year;
          when 2 then 
               year := 2100 + year;
          when 3 then 
               year := 2200 + year;
          else 
              year := 1800 + year;
    end case;
    if extract(year from new.urodzony) != year || extract(month from new.urodzony) != month || extract(day from new.urodzony) then
        raise exception 'Niepoprawny PESEL';
    end if;
 

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

