#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re

def preserve_trailing_whitespace(a, b):
    r = re.compile("(\s*)\Z", re.MULTILINE)

    s_a = re.search(r, a).group(1)
    return re.sub(r, "", b) + s_a

if __name__ == '__main__':
    data = sys.stdin.read()
    fd1_data = open(sys.argv[1], 'r').read()

    # Print without extra newline
    sys.stdout.write(preserve_trailing_whitespace(data, fd1_data))
    sys.stdout.flush()