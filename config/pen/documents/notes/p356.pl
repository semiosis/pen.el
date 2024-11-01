debt(tom,   111, 2.50).
debt(jerry, 137, 1.00).
debt(tom,   150, 4.20).
debt(jerry, 160, 2.77).
debt(tom,   172, 5.10).

debtor(Debtor) :-
    debt(Debtor, _, _).

total_debt(Debtor, Debt) :-
    setof(Invoice-Amount_Unpaid,
        debt(Debtor, Invoice, Amount_Unpaid),
        Invoice_Amounts),
    total_sum(Invoice_Amounts, 0, Debt).

total_sum([], Sum, Sum).
total_sum([_Invoice-Amount | Invoice_Amounts], Sum0, Sum) :-
    Sum1 is Sum0 + Amount,
    total_sum(Invoice_Amounts, Sum1, Sum).


print_debtor_report :-
    setof(Debtor, debtor(Debtor), Debtors),
    !,  % red cut for if-then-else effect
    print_debtor_report_header,  % mistake here
    print_debtor_lines(Debtors), % mistake here
    print_debtor_report_footer.
print_debtor_report :-
    print_null_debtor_report.

print_debtor_lines([]).
print_debtor_lines([Debtor | Debtors]) :-
    print_debtor_line(Debtor), % mistake here
    print_debtor_lines(Debtors).

print_debtor_line(Debtor) :-
    total_debt(Debtor, Debt), % mistake here
    write(Debtor), write(' owes $'), write(Debt), nl.

print_debtor_report_header :-
    true.

print_debtor_report_footer :-
    true.

print_null_debtor_report :-
    write('There are no debtors.'), nl.

