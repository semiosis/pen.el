#!/usr/bin/env pen-python

# import tensorflow as tf
# import tensorflow_hub as hub
# import matplotlib.pyplot as plt
# import numpy as np

# import os
# import pandas as pd
# import re
# import seaborn as sns

from itertools import combinations

import sys

# import shanepy
# from shanepy import *

if len(sys.argv) > 1:
    delim = sys.argv[1]
else:
    delim = " "

for line in sys.stdin:
    ## I can't split this way or I'll lose the starting space in emacs GPT autocomplete
    #  lst = line.split()
    # I must split like this
    lst = line.split(delim)
    #  print(line)
    for w in lst:
        if w and not w.isspace() and not w == "\n":
            print(w)
        break

    for start, end in combinations(range(len(lst)), 2):
        if start == 1:
            break
        print(delim.join(lst[start:end+1]))
