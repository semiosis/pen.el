#!/usr/bin/env runracketscript
#lang racket/base

;; [[zrepl-cm:excitedness.rkt --excited]]
;; [[zrepl-cm:excitedness.rkt --bye]]

(require racket/cmdline)

(define excitedness "")
(define mode "Hi")
(command-line
  #:multi
  [("-e" "--excited") "add excitedness levels"
   (set! excitedness (string-append excitedness "!"))]
  #:once-each
  [("-b" "--bye") "turn on \"bye\" mode"
   (set! mode "Bye")])

(printf "~a~a\n" mode excitedness)

