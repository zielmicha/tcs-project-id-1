Baza informacji medycznych
-----------------------------

Nasza baza to Ogólnokrajowy System informacji medycznej sieci szpitali i innych placówek z naciskiem na usługi w nich wykonywane, a w szczególności, płatności za nie. System implementuje podobne funkcjonalności co istniejące bazy NFZ (eWUŚ, ZIP).

Przyjęliśmy model w którym nieprawidłowości stwierdzane są po fakcie. Baza pozwala łatwo znaleźć w bazie nieprawidłowości np. badania wykonanie nieubezpieczonej osobie. Inne funckje obliczają koszty usług.

Bezpośrednio po wpisaniu osoby do bazy badana jest poprawność i unikalność numeru PESEL oraz daty urodzenia.

W naszej bazie nie używamy żadnych dodatkowych indeksów. Większość zapytań dotyczy id danej tabeli, które jest primary key, lub rzeczy unique takich jak PESEL osoby.


Skrypty generujące projekt znajdują się na:
https://github.com/zielmicha/tcs-project-id-1
