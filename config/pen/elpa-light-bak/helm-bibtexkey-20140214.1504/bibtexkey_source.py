#!/usr/bin/env python
# coding=utf-8

import os
from argparse import ArgumentParser


def main():
    parser = ArgumentParser(description="""
    Create bibtex candidates for emacs-helm""")
    parser.add_argument('bibtex_files', nargs="+")
    args = parser.parse_args()

    for bib_file in args.bibtex_files:
        bib_data = _read_file(_check_path(bib_file))
        for key in bib_data.entries:
            line = key + ", " + _entry_to_description(bib_data.entries[key])
            print line.encode("utf8")


def _read_file(filename):
    from pybtex.database.input import bibtex
    from pybtex import errors
    errors.enable_strict_mode()
    parser = bibtex.Parser()
    return parser.parse_file(filename)


def _check_path(path):
    path = os.path.abspath(os.path.expanduser(path))
    if not os.path.exists(path):
        raise RuntimeError("%s does not exists" % path)
    return path


def _entry_to_description(entry, sep=", "):
    try:
        persons = entry.persons[u'author']
        authors = [unicode(au) for au in persons]
    except:
        authors = [u'unknown']
    author = ", ".join(authors)
    title = entry.fields[u'title'] if u'title' in entry.fields else u""
    year = entry.fields[u'year'] if u'year' in entry.fields else u""
    journal = entry.fields[u'journal'] if u'journal' in entry.fields else u""
    return author + sep + title + sep + journal + sep + year


if __name__ == "__main__":
    main()
