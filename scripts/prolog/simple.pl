:- initialization(main).

ok(a).
ok(b).

main :-
    argument_value(1, X),
    read_from_atom(X, T),
    call(T).
