#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; https://school.racket-lang.org/2019/plan/mon-mor-lab.html

(define program-as-text "((lambda (x) (+ x 10)) 42)")

(define macro-as-text
  (string-append
   "((lambda (y)"
   "   (let-syntax (plus10"
   "               (lambda (stx)"
   "                 (match stx"
   "                   [`(plus10 ,x) `(+ ,x 10)])))"
   "     (plus10 y)))"
   " 42)"))

(define another-example
  (string-append
   "((lambda (fun)"
   "   (fun "
   "    (let-syntax (syn (lambda (stx)"
   "                         23))"
   "      (syn (fun 1) 20))))"
   " (lambda (x) (+ x 1)))"))

;; First we need to turn those strings into trees of concrete syntax, and for that we
;; need a data representation:

(struct Syntax (e {stuff #:auto}) #:transparent #:auto-value 'stuff)

;; The `Syntax` structure encapsulates the S-expressions from the olden days and
;; information about the original character string relative to these S-expressions. The
;; model represents this information with 'stuff; you may imagine data such as the source
;; file, line numbers, character numbers, and more.

(define (main year)
  ;; printf format:
  ;; https://docs.racket-lang.org/reference/Writing.html
  (printf "Extracted digits: ~s\n"
          (extract-digits year))
  (printf "Extracted digits v2: ~s\n"
          (extract-digits-version-2 year)))

;; [[zrepl:basic-macro-demo.rkt]]
