#!/usr/bin/env swipl

% initialization(:Goal, +When)
:- initialization(main, main).

main() :-
    write('Hello World').

% :- initialization(:Goal)
% # :- initialization(main).

