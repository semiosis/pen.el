#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
;; I used =<help> f= to find the require for =define-simple-macro=
(require syntax/parse/define)
(provide main)

;; https://school.racket-lang.org/2019/plan/tue-mor-lecture.html

;; Iteration macro
;; ---------------
;; We intended this macro to present an abstraction of iteration through a sequence
;; where each element of seq is bound to the identifier elem-name inside of
;; computation. However, our implementation of this macro fails to present this
;; abstraction: instead, it exposes its implementation to clients.
(define-simple-macro (simple-for/list0 ([elem-name seq]) computation)
  (map (λ (elem-name) computation) seq))

;; TODO Define a new macro, condd, that allows this program to be written as

;; (define (filter ? l)
;;   (condd [(empty? l) empty]
;;          [#:def f (first l)]
;;          [#:def fr (filter ? (rest l))]
;;          [(? f) (cons f fr)]
;;          [#:else fr]))

(define (main . xs)
  (printf "You gave me ~s flags: ~a\n"
          (length xs) (string-join xs ", ")))
