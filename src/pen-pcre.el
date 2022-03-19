(require 'pcre2el)

;; the string replace part is still a regular emacs replacement pattern, not PCRE
(defun pcre-replace-string (pat rep s &rest body)
  "Replace pat with rep in pen-str and return the result.
The string replace part is still a regular emacs replacement pattern, not PCRE"
  (eval `(replace-regexp-in-string (pcre-to-elisp pat ,@body) rep s)))

(provide 'pen-pcre)
