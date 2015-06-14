import random

print 'insert into personel_medyczny (id_osoby) values'

people = range(1, 1000)
random.shuffle(people)
tuples = ['(%d)' % i for i in people[:50]]
print ', '.join(tuples) + ';'

print 'insert into choroby (nazwa) values'
print ', '.join("('%s')" % name.strip().split("'")[0] for name in open('choroby.txt') ) + ';'

print 'insert into zatrudnieni (id_osoby, miejsce_pracy, id_czlonka_personelu_medycznego, stanowisko) values'
print ', '.join("(%d, %d, %d, '%s')" % (
    random.randrange(1, 10),
    random.randrange(1, 10),
    random.randrange(1, 10),
    random.choice(['Lekarz', 'Pielegniarka', 'Ordynator'])
) for i in xrange(40) ) + ';'
