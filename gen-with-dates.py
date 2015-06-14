import random

def gen_date():
    d = lambda: random.randrange(100)
    return '19%02d-%02d-%02d' % (d(), d(), d())
