#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

(require shell/pipeline-macro)

;; [[zrepl-cm:excitedness.rkt --excited]]
;; [[zrepl-cm:excitedness.rkt --bye]]


;; [[zrepl-cm:you-gave-me.rkt kjdlsaf sdlfkj lkdsa]]

(define (main . xs)
  ;; Pipe `ls` into `tv`
  (run-pipeline =unix-pipe= ls -l =unix-pipe= tv)
  ;; 5

  ;; The last thing goes to stdout
  ""
  
  ;; (printf "You gave me ~s flags: ~a\n"
  ;;         (length xs) (string-join xs ", "))
  )
