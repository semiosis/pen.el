#!/usr/bin/env swipl

% initialization(:Goal, +When)
:- initialization(main, main).

main() :-
    write('Hello World').

%% - Tom is a cat
%% - Kunal loves to eat Pasta
%% - Hair is black
%% - Nawaz loves to play games
%% - Pratyusha is lazy.
%% 
%% So these are some facts, that are unconditionally true. These
%% are actually statements, that we have to consider as true.

cat(tom).
loves_to_eat(kunal,pasta).
of_color(hair,black).
loves_to_play_games(nawaz).
lazy(pratyusha).
