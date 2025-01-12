;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "magit" "20241219.2012"
  "A Git porcelain inside Emacs."
  '((emacs         "27.1")
    (compat        "30.0.0.0")
    (dash          "2.19.1")
    (magit-section "4.1.3")
    (seq           "2.24")
    (transient     "20241217")
    (with-editor   "3.4.3"))
  :url "https://github.com/magit/magit"
  :commit "f637dd1877c76e89a1d423657425cdcde2e4d723"
  :revdesc "f637dd1877c7"
  :keywords '("git" "tools" "vc")
  :authors '(("Marius Vollmer" . "marius.vollmer@gmail.com")
             ("Jonas Bernoulli" . "emacs.magit@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.magit@jonas.bernoulli.dev")
                 ("Kyle Meyer" . "kyle@kyleam.com")))
