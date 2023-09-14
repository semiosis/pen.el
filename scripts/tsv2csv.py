#!/usr/bin/env python3.8
import csv, sys
csv.writer(sys.stdout).writerows(csv.reader(sys.stdin, dialect='excel-tab'))
