#!/usr/bin/env swipl

:- initialization(main, main).

%% In the docs for the main predicate, this program is an example
%% All it does is copy out the command line arguments to stdout (without preserving quotation marks)

%% TODO, perhaps starting with this script, try to make a TV predicate

main(Argv) :-
    echo(Argv).

echo([]) :- nl.
echo([Last]) :- !,
    write(Last), nl.
echo([H|T]) :-
    write(H), write(' '),
    echo(T).
