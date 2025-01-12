;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "cmake-ide" "20210610.1525"
  "Calls CMake to find out include paths and other compiler flags."
  '((emacs       "24.4")
    (cl-lib      "0.5")
    (seq         "1.11")
    (levenshtein "0")
    (s           "1.11.0"))
  :url "https://github.com/atilaneves/cmake-ide"
  :commit "28dc4ab5bd01d99553901b4efeb7234280928b18"
  :revdesc "28dc4ab5bd01"
  :keywords '("languages")
  :authors '(("Atila Neves" . "atila.neves@gmail.com"))
  :maintainers '(("Atila Neves" . "atila.neves@gmail.com")))
