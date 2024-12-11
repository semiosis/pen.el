#!/usr/bin/env runracketscriptmain
#lang typed/racket

(provide string->er)

;; (require racket/string)
(provide main)

;; https://school.racket-lang.org/2019/plan/mon-mor-lecture.html

(: string->er (String -> (U Exact-Rational False)))
(define (string->er s)
  (define r
    (parameterize
([read-decimal-as-inexact #f])
      (string->number s)))
  (and (rational? r) (exact? r)
(ann r Exact-Rational)))          

;; TODO Fix this - it's not a valid type
;; (: main (String))
;; (define (main s)
;;   (print
;;    (string->er s)))

;; TODO How to make a main function with no return type?
(: main (-> Integer))
(define (main)
  5)

;; [[zrepl:typed-racket-demo.rkt]]

