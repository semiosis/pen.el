(require 'pcase)

;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Extending-pcase.html

(pcase-defmacro re (pat)
  "Matches if EXPVAL is a regex matching pat."
  `(and (pred stringp)
        (pred (lambda (s) (re-match-p ,pat s)))))

(provide 'pen-pcase)
