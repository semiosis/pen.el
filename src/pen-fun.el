(defun pen-oob (s)
  "Replace all vowels with 'oob'"

  ;; TODO Improve this by taking into account 'y'
  (replace-regexp-in-string "[aeiou]" "oob" s))

(provide 'pen-fun)