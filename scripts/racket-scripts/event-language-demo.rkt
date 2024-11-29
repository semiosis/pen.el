#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; https://school.racket-lang.org/2019/plan/mon-mor-lecture.html

; dealing with events from the environment

(require 2htdp/universe)
(require 2htdp/image)

;; TODO Make it so s0 is converted from string into int
(define (main s0)
  (big-bang s0
            [on-tick   sub1]
            [stop-when zero?]
            [to-draw   (lambda (s) (circle (+ 100 (* s 10)) 'solid 'red))]))

;; [[zrepl:event-language-demo.rkt 40]]
