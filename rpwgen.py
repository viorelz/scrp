#!/usr/bin/python3

import string
import argparse
import random
import sys

try:
    rng = random.SystemRandom
except AttributeError:
    rng = random.Random

charSet = {'small': 'abcdefghijklmnopqrstuvwxyz',
           'nums': '0123456789',
           'big': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
           'special': '^!&()=?{[]}+~#-_.,;<>|'
          }

class Configuration(object):
    length = 16
    count = 1
    specials = True
    min_specials = 2

cfg = Configuration()

def get_config(options):
    if options.length is not None:
        cfg.length = options.length
    if options.count is not None:
        cfg.count = options.count
    if options.specials is not None:
        cfg.specials = options.specials

# ensure there are no consecutive uppercase/lowercase/numbers
def checkPreviousChar(password, currentCharSet):
    index = len(password)
    if index == 0:
        return False
    else:
        prevChar = password[index - 1]
        if prevChar in currentCharSet:
            return True
        else:
            return False

# generate a random password
def generatePassword():
    passwd = []
    passwd.append(rng().choice(charSet['small']))
    passwd.append(rng().choice(charSet['nums']))
    passwd.append(rng().choice(charSet['big']))
    if not cfg.specials:
        passwd.append(rng().choice(charSet['special']))
    while len(passwd) < cfg.length:
        key = rng().choice(list(charSet.keys()))
        a_char = rng().choice(charSet[key])
        if not cfg.specials and a_char in charSet['special']:
            continue
        if checkPreviousChar(passwd, charSet[key]):
            continue
        else:
            passwd.append(a_char)
    specials_count = 0
    for c in passwd:
        if c in charSet['special']:
            specials_count += 1
    if specials_count < cfg.min_specials:
        for i in range(cfg.min_specials):
            m = rng().randint(0, cfg.length - 1)
            passwd[m] = rng().choice(charSet['special'])
    password = ''.join(passwd)
    return password

if __name__ == '__main__':
    usage = "usage: %prog [options]"
    parser = argparse.ArgumentParser(usage)

    parser.add_argument("-l", "--length", type=int, dest="length", default=12,
                        help="Specify the password length")
    parser.add_argument("-c", "--count", type=int, dest="count", default=1,
                        help="Generate COUNT passwords")
    parser.add_argument("-s", "--specials", dest="specials", default=True, action="store_false",
                        help="Do not use special characetrs")

    options = parser.parse_args()
    get_config(options)

    passwords = []
    for i in range(cfg.count):
        pwd = generatePassword()
        passwords.append(pwd)
    # print the password(s)
    for p in passwords:
        print(p)
