#!python
#
# SUMMARY:      Outputs the [application name] of the topmost window at mouse screen position or nothing if none
# USAGE:        <script> <x-screen-coordinate> <y-screen-coordinate>
#
# REQUIRES:     macOS window system and the python2 and the PyObjC libraries available here: https://pythonhosted.org/pyobjc/install.html
#
# AUTHOR:       Bob Weiner <rsw@gnu.org>
# ORIG-DATE:    14-Oct-17 at 16:21:53
# LAST-MOD:     24-Jan-22 at 00:52:47 by Bob Weiner
#
# Copyright (C) 2017  Free Software Foundation, Inc.
# See the "HY-COPY" file for license information.
#
# DESCRIPTION:  
# DESCRIP-END.

import Quartz
from sys import argv, exit

if len(argv) < 3:
    print(f"{argv[0]}: ERROR - Call with 2 numeric arguments, X and Y representing an absolute screen position") 
    exit(1)

x = int(argv[1]); y = int(argv[2])

# Return the first window that x,y falls within since the windows are listed in z-order (top of stack to bottom)
def filter_and_print_top_window(x, y):
    win_x = win_y = win_width = win_height = 0

    for v in Quartz.CGWindowListCopyWindowInfo( Quartz.kCGWindowListOptionOnScreenOnly | Quartz.kCGWindowListExcludeDesktopElements, Quartz.kCGNullWindowID ):
        val = v.valueForKey_
        bounds_val = val('kCGWindowBounds').valueForKey_
        
        # If item has a non-zero WindowLayer, it is not an app and is probably system-level, so skip it.
        if not val('kCGWindowIsOnscreen') or val('kCGWindowLayer'):
            continue

        win_x = int(bounds_val('X')); win_y = int(bounds_val('Y'))
        win_width = int(bounds_val('Width')); win_height = int(bounds_val('Height'))

        if win_x <= x and x < win_x + win_width and win_y <= y and y < win_y + win_height:
            print('[' + ((val('kCGWindowOwnerName') or '') + ']')).encode('utf8')
            # Add this line back in if you need to see the specific window within the app at the given position.
            # + ('' if val('kCGWindowName') is None else (' ' + val('kCGWindowName') or '')) \

            break

# Filter to just the topmost window at (x,y) screen coordinates and print the bracketed [window name], if any.
filter_and_print_top_window(x, y)
