import random
import os

def gen_date():
    d = lambda v: random.randrange(1, v)
    return '19%02d-%02d-%02d' % (d(100), d(12), d(28))

def gen_two_date():
    v = [gen_date(), gen_date()]
    v.sort()
    return v

def gen_range():
    a, b = gen_two_date()
    return "'[%s, %s)'" % (a, b)


print 'insert into zgloszenie (id_osoby, id_oddzialu, okres) values'
print ', '.join("(%d, %d, %s)" % (random.randrange(1, 1000),
                                  random.randrange(1, 10), gen_range())
                for i in xrange(1000) ) + ';'

print 'insert into umowy (id_oddzialu, id_uslugodawcy, okres) values'
print ', '.join("(%d, %d, %s)" % (random.randrange(1, 10),
                                  random.randrange(1, 10), gen_range())
                for i in xrange(1000) ) + ';'


print 'insert into recepty (id_pracownika, id_osoby, id_apteki, data_wystawienia) values'
print ', '.join("(%d, %d, %d, '%s')" %
                (
                    random.randrange(1, 10), random.randrange(1, 10),
                    random.randrange(1, 10),
                    gen_date())
                for i in xrange(40) ) + ';'


print 'insert into recepta_lek (id_recepty, id_leku, refundacja, zrealizowano,' +\
    'choroba, ilosc, okres) values'
print ', '.join("(%d, %d, %d, %d, %d, %d, %s)" %
                (
                    random.randrange(1, 10),
                    random.randrange(1, 10),
                    random.randrange(0, 100),
                    random.randrange(0, 2),
                    random.randrange(1, 10),
                    random.randrange(1, 10),
                    gen_range())
                for i in xrange(40) ) + ';'


print 'insert into typy_uslug (nazwa, koszt, obowiazuje) values'
print ', '.join("('%s', %d, %s)" %
                (
                    os.urandom(5).encode('hex'),
                    random.randrange(10, 10000),
                    gen_range())
                for i in xrange(100) ) + ';'


print 'insert into uslugi (id_pracownika, id_osoby, typ, opis, oplacona, kiedy) values'
print ', '.join("(%d, %d, %d, '%s', '%s', '%s')" % (
    random.randrange(1, 10),
    random.randrange(1, 1000),
    random.randrange(1, 100),
    os.urandom(16).encode('hex'),
    random.choice(['tak', 'nie']),
    gen_date()
) for i in xrange(50) ) + ';'
