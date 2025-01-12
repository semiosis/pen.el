(define-package "magit" "20240112.2212" "A Git porcelain inside Emacs."
  '((emacs "25.1")
    (compat "29.1.4.4")
    (dash "20221013")
    (git-commit "20231030")
    (magit-section "20231202")
    (seq "2.24")
    (transient "20231204")
    (with-editor "20230917"))
  :commit "ddeaa2d69aac4c89e95ab60cf216c4c389db1a02" :authors
  '(("Marius Vollmer" . "marius.vollmer@gmail.com")
    ("Jonas Bernoulli" . "jonas@bernoul.li"))
  :maintainer
  '("Jonas Bernoulli" . "jonas@bernoul.li")
  :keywords
  '("git" "tools" "vc")
  :url "https://github.com/magit/magit")
;; Local Variables:
;; no-byte-compile: t
;; End:
