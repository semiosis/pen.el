#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)
(define (main . xs)
  (printf "You gave me ~s flags: ~a\n"
          (length xs) (string-join xs ", ")))
