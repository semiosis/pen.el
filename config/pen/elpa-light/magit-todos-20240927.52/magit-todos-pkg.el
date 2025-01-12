;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "magit-todos" "20240927.52"
  "Show source file TODOs in Magit."
  '((emacs     "26.1")
    (async     "1.9.2")
    (dash      "2.13.0")
    (f         "0.17.2")
    (hl-todo   "1.9.0")
    (magit     "2.13.0")
    (pcre2el   "1.8")
    (s         "1.12.0")
    (transient "0.2.0"))
  :url "https://github.com/alphapapa/magit-todos"
  :commit "bd27c57eada0fda1cc0a813db04731a9bcc51b7b"
  :revdesc "bd27c57eada0"
  :keywords '("magit" "vc")
  :authors '(("Adam Porter" . "adam@alphapapa.net"))
  :maintainers '(("Adam Porter" . "adam@alphapapa.net")))
