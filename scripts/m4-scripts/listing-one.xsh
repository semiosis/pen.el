#!/usr/bin/env -S xsh -p "^\$"

/usr/bin/m4
define(A, 100)dnl
define(B, A)dnl
define(C, `A')dnl
dumpdef(`A', `B', `C')dnl
dumpdef(A, B, C)dnl
A B C
