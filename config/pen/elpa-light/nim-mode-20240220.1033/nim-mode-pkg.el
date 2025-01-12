;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "nim-mode" "20240220.1033"
  "A major mode for the Nim programming language."
  '((emacs               "24.4")
    (epc                 "0.1.1")
    (let-alist           "1.0.1")
    (commenter           "0.5.1")
    (flycheck-nimsuggest "0.8.1"))
  :url "https://github.com/nim-lang/nim-mode"
  :commit "625cc023bd75a741b7d4e629e5bec3a52f45b4be"
  :revdesc "625cc023bd75"
  :keywords '("nim" "languages")
  :maintainers '(("Simon Hafner" . "hafnersimon@gmail.com")))
