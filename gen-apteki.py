# coding=utf-8
import random

oddzialy = [
    'Małopolski', 'Wielkopolski', 'Centralny',
    'Podlaski', 'Mazowiecki', 'Zielony',
    'Czerwony', 'Królowski', 'Pomarańczowy',
    'Demoniczny'
]

print 'insert into oddzialy (nazwa, adres) values'

for i, oddzial in enumerate(oddzialy):
    print "('%s', 'Długa %d')" % (oddzial, random.randrange(10000)),
    if i + 1 == len(oddzialy):
        print ';'
    else:
        print ','

print

surnames = open('surnames.txt').read().splitlines()
surnames = [surname.split()[1] + 'ego'
            for surname in surnames if surname.endswith('ski')]

print 'insert into apteki (nazwa, adres, id_oddzialu) values'
N = 10

for i in xrange(1, N + 1):
    print "('Apteka %s', '%s', %d)" % (
        random.choice(surnames),
        'Długa %d' % random.randrange(10000),
        random.randrange(1, 11)),
    print ';' if i == N else ','
