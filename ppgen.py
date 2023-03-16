#!/usr/bin/python3
# encoding: utf-8

import string
import optparse
import sys
import random

try:
    from xkcdpass import xkcd_password as xp
except ImportError:
    print('Module xkcdpass not found. Please run:\npip install xkcdpass\nas root')
    sys.exit(1)

try:
    rng = random.SystemRandom
except AttributeError:
    sys.stderr.write("WARNING: System does not support cryptographically "
                     "secure random number generator or you are using Python "
                     "version < 2.4.\n"
                     "Continuing with less-secure generator.\n")
    rng = random.Random


class Configuration(object):
    charSet = { 'small': 'abcdefghijklmnopqrstuvwxyz',
                'nums': '0123456789',
                'big': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                'special':'^!&()=?{[]}+~#-_.:,;<>|',
                'alpha': 'ABCDEFGHIJKLMNPQRSTUVWXYZ0123456789abcdefghijkmnopqrstuvwxyz'
              }
    rng = ''
    passwd = []
    delimiters = []
    digits = []

    minLength = 3
    maxLength = 8
    numWords = 3
    forceDelimiter = False
    count = 1
    upperCase = False
    lowerCase = False
    capitalize = False
    acrostic = False
    interactive = False
    validChars = "."
    padCount = 3
    padFront = True
    padEnd = False
    padSet = False
    wordfile = xp.locate_wordfile()

    def __init__(self):
        try:
            self.rng = random.SystemRandom
        except AttributeError:
            self.rng = random.Random

        for i in range(len(self.charSet['special'])):
            self.delimiters.append(self.charSet['special'][i])

        for i in range(len(self.charSet['nums'])):
            self.digits.append(self.charSet['nums'][i])

        self.delimiter = self.rng().choice(self.delimiters)
        self.padChar = self.rng().choice(self.digits)
        self.wordfile = xp.locate_wordfile()

cfg = Configuration()


def get_config(options):
    if options.min_length is not None:
        cfg.minLength = options.min_length
    if options.max_length is not None:
        cfg.maxLength = options.max_length
    if options.numwords is not None:
        cfg.numWords = options.numwords
    if options.interactive is not None:
        cfg.interactive = options.interactive
    if options.valid_chars is not None:
        cfg.validChars = options.valid_chars
    if options.acrostic is not None:
        cfg.acrostic = options.acrostic
    if options.count is not None:
        cfg.count = options.count
    if options.delimiter is not None:
        cfg.delimiter = options.delimiter
        cfg.forceDelimiter = True
    if options.uppercase is not None:
        cfg.upperCase = options.uppercase
    if options.lowercase is not None:
        cfg.lowerCase = options.lowercase
    if options.capitalise is not None:
        cfg.capitalize = options.capitalise
    if options.padfront is not None:
        cfg.padFront = options.padfront
    if options.padend is not None:
        cfg.padEnd = options.padend
    if options.padchar is not None:
        cfg.padChar = options.padchar
        cfg.padSet = True
    if options.padcount is not None:
        cfg.padCount = options.padcount
        if cfg.padCount == 0:
            cfg.padFront = cfg.padEnd = False


def validate_options(parser, options, args):
    if options.max_length is not None and options.min_length is not None:
        if options.max_length < options.min_length:
            sys.stderr.write("The maximun length of a word can not be lesser then the minimum length.\n"
                             "Check the appropriate settings.\n")
            sys.exit(1)

        if len(args) > 1:
            parser.error("Too many arguments.")

        if len(args == 1):
            # supporting either -w or args[0] for wordlist, but not both
            if options.wordfile is None:
                options.wordfile = args[0]
            elif options.wordfile == args[0]:
                pass
            else:
                parser.error("Conflicting values for wordlist: " + args[0] +
                             " and " + options.wordfile)
        if options.wordfile is not None:
            if not os.path.exists(os.path.abspath(options.wordfile)):
                sys.stderr.write("Could not open the specified word file.\n")
                sys.exit(1)
        else:
            options.wordfile = xp.locate_wordfile()
            if not options.wordfile:
                sys.stderr.write("Could not find a word file, or word file does not exist.\n")
                sys.exit(1)


def main():
    usage = "usage: %prog [options]"
    parser = optparse.OptionParser(usage)

    parser.add_option("-w", "--wordfile", dest="wordfile", default = None, metavar="WORDFILE",
                      help=("Specify that the file WORDFILE contains the list of valid words"
                            " from which to generate passphrases."))
    parser.add_option("--min", dest="min_length", type="int", default= None, metavar="MIN_LENGTH",
                      help="Generate passphrases containing at least MIN_LENGTH words.")
    parser.add_option("--max", dest="max_length", type="int", default= None, metavar="MAX_LENGTH",
                      help="Generate passphrases containing at least MAX_LENGTH words.")
    parser.add_option("-n", "--numwords", dest="numwords", default= None, metavar="NUMWORDS",
                      help="Generate passphrases containing exactly NUMWORDS words.")
    parser.add_option("-i", "--interactive", action="store_true", dest="interactive", default=None,
                      help=("Generate and display a passphrase, ask the user to accept it,"
                            " and loop until one is accepted"))
    parser.add_option("-v", "--valid_chars", dest="valid_chars", default=None, metavar="VALID_CHARS",
                      help=("Limit passphrases to only include words matching the regex"
                      " pattern VALID_CHARS (e.g. '[a-z]')."))
    parser.add_option("-a", "--acrostic", dest="acrostic", default=None, metavar="ACROSTIC",
                      help="Generate passphrases with an acrostic matching ACROSTIC")
    parser.add_option("-c", "--count", dest="count", type="int", default=None, metavar="COUNT",
                      help="Generate COUNT passphrases")
    parser.add_option("-d", "--delimiter", dest="delimiter", default=None, metavar="DELIMITER",
                      help="Separate words within passphrase with DELIMITER")
    parser.add_option("-U", "--uppercase", dest="uppercase", default=None, action="store_true", metavar="UPPERCASE",
                      help="Force passphrase to uppercase.")
    parser.add_option("-L", "--lowercase", dest="lowercase", default=None, action="store_true", metavar="LOWERCASE",
                      help="Force passphrase to lowercase.")
    parser.add_option("-C", "--capitalise", "--capitalize", dest="capitalise", default=None, action="store_true",
                      help="Generate passphrase with all words capitalised")
    parser.add_option("--pad_front", dest="padfront", default=None, action="store_true", metavar="PADFRONT",
                      help="Pad the passphrase at the beginning.")
    parser.add_option("--pad_end", dest="padend", default=None, action="store_true", metavar="PADEND",
                      help="Pad the passphrase at the end.")
    parser.add_option("--pad_char", dest="padchar", default= None, metavar="PADCHAR",
                      help="Padding character.")
    parser.add_option("--pad_count", dest="padcount", type="int", default=None, metavar="PADCOUNT",
                      help="Pad the passphrase at the beginning.")


    (options, args) = parser.parse_args()
    validate_options(parser, options, args)
    get_config(options)
    mywords = xp.generate_wordlist(cfg.wordfile,
                                   min_length=cfg.minLength,
                                   max_length=cfg.maxLength,
                                   valid_chars=cfg.validChars)

    for i in range(cfg.count):
        if not cfg.forceDelimiter:
            cfg.delimiter = rng().choice(cfg.delimiters)
#            print cfg.delimiter, cfg.forceDelimiter
        pwd = xp.generate_xkcdpassword(mywords,
                                       interactive=cfg.interactive,
                                       numwords=cfg.numWords,
                                       acrostic=cfg.acrostic,
                                       delimiter=cfg.delimiter)

        if cfg.upperCase:
            pwd = pwd.upper()
        elif cfg.lowerCase:
            pwd = pwd.lower()
        elif cfg.capitalize:
            pwd = string.capwords(pwd, cfg.delimiter)

        if not cfg.padSet:
            cfg.padChar = rng().choice(cfg.digits)
        if cfg.padCount > 0:
            padStr = ""
            for i in range(cfg.padCount):
                padStr += cfg.padChar
            if cfg.padFront:
                pwd = padStr + cfg.delimiter + pwd
            if cfg.padEnd:
                pwd = pwd + cfg.delimiter + padStr

        print(pwd)

if __name__ == '__main__':
    main()
