#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import itertools

def ranges(i):
    for a, b in itertools.groupby(enumerate(i), lambda pair: pair[1] - pair[0]):
        b = list(b)
        yield b[0][1], b[-1][1]

all_input = sys.stdin.read()

# Split the input string into individual elements
input_list = all_input.split()

# Convert each element into an integer
numbers = [int(num) for num in input_list]

# print(list(ranges(numbers)))
for a, b in list(ranges(numbers)):
    if a == b:
        print("%d" % (a))
    else:
        print("%d-%d" % (a, b))