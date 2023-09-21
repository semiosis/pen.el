#!/usr/bin/perl
# $XTermId: 256colors.pl,v 1.4 2006/09/29 21:49:03 tom Exp $
# -----------------------------------------------------------------------------
# this file is part of xterm
#
# Copyright 1999,2006 by Thomas E. Dickey
# 
#                         All Rights Reserved
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE ABOVE LISTED COPYRIGHT HOLDER(S) BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# Except as contained in this notice, the name(s) of the above copyright
# holders shall not be used in advertising or otherwise to promote the
# sale, use or other dealings in this Software without prior written
# authorization.
# -----------------------------------------------------------------------------
#
# This uses 33 print-lines on an 80-column display.  Printing the numbers in
# hexadecimal would make it compact enough for 24x80, but less readable.

for ($bg = 0; $bg < 256; $bg++) {
  # print "\x1b[9;1H\x1b[2J";
  for ($fg = 0; $fg < 256; $fg++) {
    print "\x1b[48;5;${bg}m\x1b[38;5;${fg}m";
    # printf "%03.3d/%03.3d ", $fg, $bg;
    printf "%03.3d ", $fg;
  }
  exit 0;
  print "\n";
  sleep 1;
}
