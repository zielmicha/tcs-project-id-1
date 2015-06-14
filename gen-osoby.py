import random

names = open('names.txt').read().splitlines()
surnames = open('surnames.txt').read().splitlines()

def feminize(surname):
    if surname.endswith('ski'):
        return surname[:-1] + 'a'
    else:
        return surname

print 'insert into osoby (pesel, imie, nazwisko, plec, urodzony) values'

N = 1000

def cyfra(pesel):
    a = [0] + map(int, pesel)
    c = (1 * a[1] + 3 * a[2] + 7 * a[3] + 9 * a[4] + 1 * a[5] + 3 * a[6] + 7 * a[7] + 9 * a[8]
         + 1 * a[9] + 3 * a[10])
    return (-c) % 10

for i in xrange(1, N + 1):
    namepair = random.choice(names).split()[1:]
    female = random.choice([True, False])
    name = namepair[1 - female]
    surname = random.choice(surnames).split()[1]
    if female:
        surname = feminize(surname)

    pesel_i = random.randrange(0, 10 ** 10 / 2) * 2
    if not female:
        pesel_i += 1
    pesel = str(pesel_i).rjust(10, '0')
    pesel += str(cyfra(pesel))

    print "('%s', '%s', '%s', '%s', '%s')" % (pesel, name, surname, 'kobieta' if female else 'mezczyzna',
                                              '19%s-%02d-%02d' % (pesel[:2], int(pesel[2:4]) % 12 + 1, int(pesel[4:6]) % 28 + 1 )),
    if i == N:
        print ';'
    else:
        print ','
