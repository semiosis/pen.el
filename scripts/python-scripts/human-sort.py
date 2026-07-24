#!/usr/bin/env python3.10
# -*- coding: utf-8 -*-

import sys
import re

# https://nedbatchelder.com/blog/202503/human_sorting_improved
def human_key(s: str) -> tuple[list[str | int], str]:
    """Turn a string into a sortable value that works how humans expect.

    "z23A" -> (["z", 23, "a"], "z23A")

    The original string is appended as a last value to ensure the
    key is unique enough so that "x1y" and "x001y" can be distinguished.

    """
    def try_int(s: str) -> str | int:
        """If `s` is a number, return an int, else `s` unchanged."""
        try:
            return int(s)
        except ValueError:
            return s

    return ([try_int(c) for c in re.split(r"(\d+)", s.casefold())], s)

# def human_sort(strings: list[str]) -> list[str]:
#     """Sort a list of strings how humans expect."""
#     return strings.sort(key=human_key)

def human_sort(strings: list[str]) -> None:
    """Sort a list of strings how humans expect."""
    strings.sort(key=human_key)

all_input = sys.stdin.read()

# Split the input string into individual lines
input_list = all_input.splitlines(keepends=False)

# sorted_lines = human_sort(input_list)
sorted_lines = input_list.sort(key=human_key)

for l in sorted_lines:
    print(l)