drop table if exists osoby cascade;
drop table if exists lekarze cascade;
drop table if exists specjalizacje cascade;
drop table if exists uslugodawcy cascade;
drop table if exists typy_uslug cascade;
drop table if exists uslugi cascade;
drop table if exists oddzialy cascade;
drop table if exists apteki cascade;
drop table if exists recepty cascade;
drop table if exists leki cascade;
drop table if exists recepta_lek cascade;
drop table if exists zgloszenie cascade;
drop table if exists umowy cascade;
drop table if exists zatrudnieni cascade;
drop table if exists choroby cascade;

drop function if exists czy_ma_umowe(placowka bigint, kiedy timestamp) cascade;
drop function if exists czy_ubezpieczony(czlowiek int, kiedy timestamp) cascade;
drop function if exists pesel_trigger() cascade;

drop view if exists lekarze_dane;
drop view if exists recepty_koszt;