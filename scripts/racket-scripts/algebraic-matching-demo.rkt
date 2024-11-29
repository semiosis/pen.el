;; TODO Make this into some kind of demo script

;; https://school.racket-lang.org/2019/plan/mon-mor-lecture.html

;; Here is an example concerning algebraic matching. The grammar production of match
;; patterns is extensible:

(define (private-adder x) (map add1 x))

(define-match-expander adder
  (lambda (stx)
    (syntax-parse stx
      [(_ x ...) #'(? (curry equal? (private-adder (list x ...))))]))

  (lambda (stx)
    (syntax-parse stx
      [(_ x ...) #'(private-adder (list x ...))])))

;; This extension allows the expression (adder 1 2 3) to mean one thing in a Racket
;; expression context:

(adder 1 2 3)

;; and something completely different in a Racket pattern context:

(match '(2 3 4)
  [(adder 1 2 3) "success!"]
  [else "** failure **"])
