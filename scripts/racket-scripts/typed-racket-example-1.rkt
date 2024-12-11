#!/usr/bin/env runracketscriptmain
#lang typed/racket

;; (provide string->er)

;; (require racket/string)
(provide main)

;; https://docs.racket-lang.org/ts-guide/quick.html

(struct pt ([x : Real] [y : Real]))

;; https://docs.racket-lang.org/ts-guide/beginning.html
;; This declares that distance has the type (-> pt pt Real).
;; The type (-> pt pt Real) is a function type, that is, the type of a procedure. The input type, or domain, is two arguments of type pt, which refers to an instance of the pt structure. The -> indicates that this is a function type. The range type, or output type, is the last element in the function type, in this case Real.
(: distance (-> pt pt Real))
(define (distance p1 p2)
  (sqrt (+ (sqr (- (pt-x p2) (pt-x p1)))
           (sqr (- (pt-y p2) (pt-y p1))))))

;; (define (main . xs)
;;   (printf "~a :: ~a\n" "hello"  'String))

(: main (-> Integer))
(define (main)
  5
  ;; (print
  ;;  (string->er s))
  )
