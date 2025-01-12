;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "org-roam" "20241007.1704"
  "A database abstraction layer for Org-mode."
  '((emacs         "26.1")
    (dash          "2.13")
    (org           "9.4")
    (emacsql       "20230228")
    (magit-section "3.0.0"))
  :url "https://github.com/org-roam/org-roam"
  :commit "2a630476b3d49d7106f582e7f62b515c62430714"
  :revdesc "2a630476b3d4"
  :keywords '("org-mode" "roam" "convenience")
  :authors '(("Jethro Kuan" . "jethrokuan95@gmail.com"))
  :maintainers '(("Jethro Kuan" . "jethrokuan95@gmail.com")))
