#!/usr/bin/env python3

# MIT License

# Copyright (c) 2019 johan.walles@gmail.com

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# http://github.com/walles/shellprof

"""Profile a shell script

Or actually anything printing to stdout.

Usage: shellprof <command> [args] ...

This will run <command>, and after it is done shellprof will print
a profile of which lines were shown the longest.

Web page: https://github.com/walles/shellprof
"""

import sys
import time
import operator
import subprocess

from typing import List, Tuple

TOP_LIST_ROWS = 10

PROGRAM_START_MARKER = "<<<PROGRAM START>>>\n"
PROGRAM_END_MARKER = "<<<PROGRAM END>>>\n"

if len(sys.argv) < 2:
    # One is the executable (this script) name, the rest are command lines
    print("ERROR: Please specify a command line to run")
    print()
    print(__doc__)
    sys.exit(1)

if sys.argv[1] in ["--help", "-h"]:
    print(__doc__)
    sys.exit()

timestamped_lines: List[Tuple[float, str]] = []

# Popen scans $PATH for executables, so this should work as people expect
with subprocess.Popen(
    sys.argv[1:], bufsize=1, stdout=subprocess.PIPE, text=True
) as child:
    timestamped_lines.append((time.time(), PROGRAM_START_MARKER))
    while True:
        stdout = child.stdout
        assert stdout
        line: str = stdout.readline()
        if line == "":
            # The empty string here is just an EOF-marker and shouldn't
            # be treated as part of our child's output.
            break

        timestamp = time.time()
        timestamped_lines.append((timestamp, line))

        # Line collected, now pass it on
        sys.stdout.buffer.write(line.encode())
        sys.stdout.buffer.flush()

timestamped_lines.append((time.time(), PROGRAM_END_MARKER))

# Compute performance stats
durationstamped_lines: List[Tuple[float, str]] = []
previous_line = timestamped_lines[0]
for timestamped_line in timestamped_lines[1:]:
    durationstamped_lines.append(
        (timestamped_line[0] - previous_line[0], previous_line[1])
    )
    previous_line = timestamped_line

durationstamped_lines.sort(key=operator.itemgetter(0), reverse=True)

print("")
print("Timings for printed lines:")

printcount = 0
for durationstamped_line in durationstamped_lines:
    duration = durationstamped_line[0]
    line = durationstamped_line[1]
    sys.stdout.buffer.write(b"%.2fs: " % duration)
    sys.stdout.buffer.write(line.encode())

    printcount += 1
    if printcount >= TOP_LIST_ROWS:
        break
