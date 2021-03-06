begin;

create table osoby (
       id serial primary key,
       imie varchar(150) not null,
       nazwisko varchar(150) not null,
       urodzony date check( urodzony <= CURRENT_DATE) not null,
       plec varchar(150) check(plec = 'kobieta' or plec = 'mezczyzna') not null,
       pesel char(11) unique not null
);

create table uslugodawcy (
       id serial primary key,
       nazwa varchar(150) not null,
       adres varchar(150) not null
);

create table zatrudnieni (
    id serial primary key,
    id_osoby int references osoby(id) not null,
    miejsce_pracy int references uslugodawcy (id),
    stanowisko varchar(150) not null
);

create table specjalizacje (
       id serial primary key,
       id_pracownika int references zatrudnieni(id) not null,
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
       id_pracownika int references zatrudnieni(id) not null,
       id_osoby int references osoby(id) not null,
       typ int references typy_uslug(id) not null,
       opis text,
       oplacona varchar check(oplacona = 'tak' or oplacona = 'nie') not null,
       kiedy timestamp
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
       id_oddzialu int references oddzialy(id) not null
);

create table recepty (
       id serial primary key,
       id_pracownika int references zatrudnieni(id) not null,
       id_osoby int references osoby(id) not null,
       id_apteki int references apteki(id),
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
       id_recepty int references recepty(id) not null,
       id_leku int references leki(id) not null,
       refundacja int default 0 check (refundacja between 0 and 100),
       zrealizowano int default 0 check(zrealizowano between 0 and 1),
       choroba int references choroby(id),
       ilosc int,
       okres tsrange
);

create table zgloszenie (
       id serial primary key,
       id_osoby int references osoby(id) not null,
       id_oddzialu int references oddzialy(id) not null,
       okres tsrange not null
);

create table umowy (
       id serial primary key,
       id_oddzialu int references oddzialy(id) not null,
       id_uslugodawcy int references uslugodawcy(id) not null,
       okres tsrange not null
);

create table historia_chorob (
    id serial primary key,
    id_osoby int references osoby(id) not null,
    id_choroby int references choroby(id) not null
);

create table historia_wyplat (
    id serial primary key,
    id_osoby int references zatrudnieni(id) not null,
    wyplata numeric(9,2) check(wyplata > 0) not null,
    tytul varchar(150) not null
);

create function czy_ubezpieczony (czlowiek int, kiedy timestamp default now()) returns bool as $$
       select count(*) > 0
              from zgloszenie where id_osoby = czlowiek
                                and okres @> kiedy;

$$ language sql;


create view osoby_naleznosci as select osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel, sum(typy_uslug.koszt) as "suma"
                from osoby
                  left join uslugi on(osoby.id = uslugi.id_osoby )
                  left join typy_uslug on (uslugi.typ = typy_uslug.id)
                  where uslugi.oplacona = 'nie'
                  group by osoby.id;

create view ubezpieczenia_pracownicy as select distinct osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel,
      (case when czy_ubezpieczony(zatrudnieni.id_osoby) then 'UBEZPIECZONY' else 'BRAK UBEZPIECZENIA' end) as "czy_ubezpieczony"
      from zatrudnieni
        join osoby on zatrudnieni.id_osoby = osoby.id
        order by osoby.nazwisko;

create function czy_ma_umowe (placowka bigint, kiedy timestamp default now()) returns bool as $$
       select count(*) > 0
              from umowy where id_uslugodawcy = placowka
                               and okres @> kiedy;
$$ language sql;

create function koszt_uslug(osoba int) returns numeric(9, 2) as
$$
declare a numeric(9, 2);
begin
a=(
SELECT SUM(b.koszt)
FROM uslugi a JOIN typy_uslug b ON a.typ=b.id
WHERE a.id_osoby=osoba
);
return a;
end;
$$
language plpgsql;

create function czy_personel_jest_ok (personel int, kiedy timestamp default now())
       returns bool as $$
      select count(*) > 0
              from zatrudnieni
              where id = personel
                and czy_ma_umowe(miejsce_pracy, kiedy);
$$ language sql;

create view uslugodawcy_uslugi as select
    uslugodawcy.id, uslugodawcy.nazwa, uslugi.id as "id usługi",
    typy_uslug.nazwa as "nazwa usługi"
      from uslugodawcy
            join zatrudnieni on zatrudnieni.miejsce_pracy = uslugodawcy.id
            join uslugi on zatrudnieni.id = uslugi.id_pracownika
            join typy_uslug on typy_uslug.id = uslugi.typ
            order by 1, 3;

create view uslugi_bez_ubezpieczenia as select a.id as "id_osoby", a.imie, a.nazwisko, b.id as "id_uslugi", b.opis, b.kiedy
FROM osoby a JOIN uslugi b ON a.id=b.id_osoby
WHERE czy_ubezpieczony(a.id, b.kiedy) = false
ORDER BY 1, 4;

create view zatrudnieni_dane as select zatrudnieni.id, osoby.imie, osoby.nazwisko, osoby.pesel
      from zatrudnieni
            left join osoby on zatrudnieni.id_osoby = osoby.id
            order by osoby.nazwisko, osoby.id;

create view zatrudnieni_specjalizacje as SELECT s.id,  array_agg(g.specjalizacja) as specjalizacja
      from zatrudnieni s
        left join specjalizacje g ON g.id_pracownika = s.id
        group by s.id
        order by 1;

create view choroby_osob as
  select a.id, a.imie, a.nazwisko, array_agg(c.nazwa) as "choroby"
  from osoby a left join (historia_chorob b JOIN choroby c ON b.id_choroby=c.id) ON a.id=b.id_osoby
  group by a.id
  order by a.id;

create view recepty_koszt as select recepty.id, recepty.id_osoby,
       sum(koszt * ilosc) as "koszt",
       czy_ubezpieczony(recepty.id_osoby, recepty.data_wystawienia),
       czy_personel_jest_ok(recepty.id_pracownika, recepty.data_wystawienia)
       from recepty
            left join recepta_lek on id_recepty = recepty.id
            join leki on id_leku = leki.id
            group by recepty.id;

create view recepty_refundacja as select recepty.id, recepty.id_osoby,
       sum( (koszt * ilosc * refundacja)::numeric / 100  )::numeric(9, 2) as "refundacja"
       from recepty
            left join recepta_lek on id_recepty = recepty.id
            join leki on id_leku = leki.id
            group by recepty.id
            having
            czy_ubezpieczony(recepty.id_osoby, recepty.data_wystawienia) and
            czy_personel_jest_ok(recepty.id_pracownika,
                                 recepty.data_wystawienia);

create view zatrudnieni_leki as select osoby.imie, osoby.nazwisko, zatrudnieni.id,
recepty.id_osoby as "pacjent", recepty.id as "id recepty",
recepty.data_wystawienia as "data",leki.nazwa, recepta_lek.zrealizowano

       from zatrudnieni
            join osoby on osoby.id = zatrudnieni.id_osoby
            join recepty on zatrudnieni.id = recepty.id_pracownika
            join recepta_lek on id_recepty = recepty.id
            join leki on recepta_lek.id_leku =  leki.id
            order by 2, 1, zatrudnieni.id;

create view uslugi_koszt as select
       id_pracownika,
       (select miejsce_pracy from zatrudnieni
               where id = id_pracownika) as placowka,
       id_osoby, typ, opis, oplacona, kiedy,
       (case when oplacona = 'tak' or not czy_ubezpieczony(id_osoby, kiedy)
       then 0 else
            (select koszt from typy_uslug where typy_uslug.id = typ)
       end) as koszt
       from uslugi;

create view nieprawidlowe_uslugi as select
      id_pracownika,
       (select miejsce_pracy from zatrudnieni
               where id = id_pracownika) as placowka,
       id_osoby, typ, opis, oplacona, kiedy
       from uslugi
       where czy_ubezpieczony(id_osoby, kiedy);

create view uslugi_koszt_dla_plac as select
       placowka, sum(koszt)
       from uslugi_koszt group by placowka;

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
          raise exception 'Niepoprawny PESEL (kobieta %)', a;
      end if;
    else if a[10]%2 = 0 then
          raise exception 'Niepoprawny PESEL (mężczyzna %)', a;
         end if;
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
