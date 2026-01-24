#!/usr/bin/env mypython

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

for line in sys.stdin:
    lst = line.split()
    #  print(line)
    for w in lst:
        print(w)

    for start, end in combinations(range(len(lst)), 2):
        print(' '.join(lst[start:end+1]))
