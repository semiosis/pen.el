#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

(define (main . xs)
  (let ([a (read)]
        [b (read)])
    (printf "~a~%" (+ a b)))

  (println (format "~a :: ~a\n" "hello" 'String))
  (printf "~a :: ~a\n" "hello"  'String))


