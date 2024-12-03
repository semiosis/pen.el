#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; [[zrepl-cm:you-gave-me.rkt kjdlsaf sdlfkj lkdsa]]

(define (main . xs)
  (printf "You gave me ~s flags: ~a\n"
          (length xs) (string-join xs ", ")))
