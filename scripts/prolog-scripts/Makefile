.PHONY: run

# gnu prolog
simple: simple.pl
	gplc --no-top-level $<

run: simple
	./simple 'forall(ok(X), (write(X), nl)).'
