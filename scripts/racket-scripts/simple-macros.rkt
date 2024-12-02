#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; https://school.racket-lang.org/2019/plan/mon-aft-lab.html

;; Filter function
(define (filter ? l)
  (cond [(empty? l) empty]
        [else
         (define f (first l))
         (define fr (filter ? (rest l)))
         (cond [(? f) (cons f fr)]
               [else fr])]))

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
