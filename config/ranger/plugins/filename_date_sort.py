# Compatible with ranger 1.6.0 through 1.7.*
#
# This plugin adds the sorting algorithm called 'pathdate'.  To enable it, type
# ":set sort=pathdate" or create a key binding with ":map od set sort=pathdate"

from __future__ import (absolute_import, division, print_function)

from random import random

from ranger.container.directory import Directory

# This import made ranger very slow
#  from shanepy import t
import os
import re
import functools

# def extract_date(path):
#     try:
#         return re.match("(\d+)\.(\d+)\.(\d+)", path).group()
#     except:
#         return None
#     # return b("rosie-extract-date", path)[0][:-1]

# This works well now
def sort_by_pathdate(path):
    path = os.path.basename(str(path))
    try:
        gs = re.match("[^0-9]*(\d+)\.(\d+)\.(\d+).*", path).groups()
        #return t(int(gs[0]) + 100 * int(gs[1]) + 10000 * int(gs[2]))
        return int(str(gs[2]) + str(gs[1]) + str(gs[0]))
        # return int(gs[0]) + 100 * int(gs[1]) + 10000 * int(gs[2])
        # return t(1)
    except:
        # return t(0)
        return 0

    # I can't do it this way because I need the entire list of paths.
    # Instead, I must use a hash function
    # b("sort -t . -n -k 3,3 -k 2,2 -k 1,1", b("ls /home/shane/notes/ws/tabs")[0])[0]

# The function must return a number. The numbers are then compared
# Directory.sort_dict['pathdate'] = lambda path: tv(path)
Directory.sort_dict['pathdate'] = sort_by_pathdate