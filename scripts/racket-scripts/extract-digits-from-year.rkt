#!/usr/bin/env runracketscriptmain
#lang racket/base
(require racket/string)
(provide main)

;; https://school.racket-lang.org/2019/plan/mon-mor-lecture.html

(define (extract-digits year)
  (regexp-match "20(.)(.)" year))

;; #px is a language of regular expressions
;; where \d matches only digits

; String -> False of [List String Digit-String Digit-String])
(define (extract-digits-version-2 year)
  (regexp-match #px"20(\\d)(\\d)" year))

(define (main year)
  ;; printf format:
  ;; https://docs.racket-lang.org/reference/Writing.html
  (printf "Extracted digits: ~s\n"
          (extract-digits year))
  (printf "Extracted digits v2: ~s\n"
          (extract-digits-version-2 year)))

;; [[zrepl:extract-digits-from-year.rkt "2018"]]
;; [[zrepl:extract-digits-from-year.rkt "1999"]]
;; [[zrepl:extract-digits-from-year.rkt "20ab"]]
