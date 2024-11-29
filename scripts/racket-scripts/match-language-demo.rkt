#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; TODO Get the necessary require to get 'match'

;; https://school.racket-lang.org/2019/plan/mon-mor-lecture.html

(define simple-tree '(a 1 2 3))

(define (main)
  (print
   (match simple-tree
     [`(a ,(? number? x) ,y) (+ x y)]
     [`(a ,x ,y ,z) (* (+ x y) z)]
     [else "error"])))

;; [[zrepl:match-language-demo.rkt]]
