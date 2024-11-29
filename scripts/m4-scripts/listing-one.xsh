#!/usr/bin/env xsh

m4
define(A, 100)dnl
define(B, A)dnl
define(C, `A’)dnl
dumpdef(`A’, `B’, `C’)dnl
A: 100
B: 100
C: A
dumpdef(A, B, C)dnl
stdin:5: m4: Undefined name 100
stdin:5: m4: Undefined name 100
stdin:5: m4: Undefined name 100
A B C
100 100 100
CTRL-D
