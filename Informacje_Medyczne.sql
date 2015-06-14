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
create table personel_medyczny (
       id serial primary key,
       id_osoby serial references osoby(id) not null
);

create table zatrudnieni (
    id serial primary key,
    id_osoby serial references osoby(id) not null,
    miejsce_pracy serial references uslugodawcy (id),
    id_czlonka_personelu_medycznego serial references personel_medyczny (id),
    stanowisko varchar(150) not null
);

create table specjalizacje (
       id serial primary key,
       id_czlonka_personelu_medycznego serial references personel_medyczny(id) not null,
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
       id_czlonka_personelu_medycznego serial references personel_medyczny(id) not null,
       id_osoby serial references osoby(id) not null,
       id_uslugodawcy serial references uslugodawcy(id) not null,
       typ serial references typy_uslug(id) not null,
       opis text,
       oplacona varchar check(oplacona = 'tak' or oplacona = 'nie') not null
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
       id_czlonka_personelu_medycznego serial references personel_medyczny(id) not null,
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
       zrealizowano int default 0 check(zrealizowano between 0 and 1),
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
    id_choroby serial references choroby(id) not null
);

create table zatrunieni_wyplaty (
    id serial primary key,
    id_zatrudnionego serial references zatrudnieni(id)  not null,
    pensja_miesieczna numeric(9,2),
    --pensja_tygodniowa numeric(9,2),
    procent_od_uslugi numeric(9,2) check( procent_od_uslugi <= 100 and procent_od_uslugi>=0)
);



create table naleznosci_za_uslugi (
    id serial primary key,
    id_zatrudnionego serial references zatrudnieni(id) not null,
    id_uslugi serial references uslugi(id) not null,
    koszt numeric(9,2),
    zaplacono varchar(5) check(zaplacono = 'tak' or zaplacono = 'nie')

);
/*
create table oplaty_za_uslugi (
    id serial primary key,
    id_osoby references references(osoby.id) not null,
    id_uslugi serial references uslugi(id) not null,
);*/

create table historia_wyplat (
    id serial primary key,
    id_osoby serial references zatrudnieni(id) not null,
    wyplata numeric(9,2) check(wyplata > 0) not null,
    tytul varchar(150) not null
);




create function czy_ubezpieczony (czlowiek int, kiedy timestamp default now()) returns bool as $$
       select count(*) > 0
              from zgloszenie where id_osoby = czlowiek
                                and okres @> kiedy;


$$ language sql;

create view personel_wyplaty_za_uslugi as select osoby.id, osoby.imie, osoby.nazwisko,
                  round(sum(zatrunieni_wyplaty.procent_od_uslugi * naleznosci_za_uslugi.koszt )/100, 2)
                  from osoby
                    left join zatrudnieni on (zatrudnieni.id_osoby = osoby.id)
                    left join zatrunieni_wyplaty on ( zatrunieni_wyplaty.id_zatrudnionego = zatrudnieni.id)
                    left join naleznosci_za_uslugi on (zatrudnieni.id = naleznosci_za_uslugi.id_zatrudnionego)
                    group by osoby.id;

create view osoby_naleznosci as select osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel, sum(typy_uslug.koszt)
                from osoby
                  left join uslugi on(osoby.id = uslugi.id_osoby )
                  left join typy_uslug on (uslugi.typ = typy_uslug.id)
                  where uslugi.oplacona = 'nie'
                  group by osoby.id;

create view ubezpieczenia_pracownicy as select osoby.id, osoby.imie, osoby.nazwisko, osoby.pesel,
      CASE WHEN czy_ubezpieczony(personel_medyczny.id_osoby) THEN 'UBEZPIECZONY' ELSE 'BRAK UBEZPIECZENIA' END
      from zatrudnieni
        left join personel_medyczny on zatrudnieni.id_czlonka_personelu_medycznego = personel_medyczny.id
        join osoby on personel_medyczny.id_osoby = osoby.id
        order by osoby.nazwisko;




create function czy_ma_umowe (placowka bigint, kiedy timestamp default now()) returns bool as $$
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


create view personel_medyczny_dane as select personel_medyczny.id, osoby.imie, osoby.nazwisko, osoby.pesel
      from personel_medyczny
            left join osoby on personel_medyczny.id_osoby = osoby.id
            order by osoby.nazwisko, osoby.id;

create view personel_medyczny_specjalizacje as SELECT s.id,  array_agg(g.specjalizacja) as specjalizacja
      FROM personel_medyczny s
        LEFT JOIN specjalizacje g ON g.id_czlonka_personelu_medycznego = s.id
        GROUP BY s.id
        order by 1;

create view choroby_osob as
  SELECT a.id, a.imie, a.nazwisko, array_agg(c.nazwa) as "choroby"
  FROM osoby a LEFT JOIN (historia_chorob b JOIN choroby c ON b.id_choroby=c.id) ON a.id=b.id_osoby
  GROUP BY a.id
  ORDER BY a.id;


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

create view personel_medyczny_leki as select osoby.imie, osoby.nazwisko, personel_medyczny.id,
recepty.id_osoby as "pacjent", recepty.id as "id recepty",
recepty.data_wystawienia as "data",leki.nazwa, recepta_lek.zrealizowano

       from personel_medyczny
            join osoby on osoby.id = personel_medyczny.id_osoby
            join recepty on personel_medyczny.id = recepty.id_czlonka_personelu_medycznego
            join recepta_lek on id_recepty = recepty.id
            join leki on recepta_lek.id_leku =  leki.id
            order by 2, 1, personel_medyczny.id;




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
