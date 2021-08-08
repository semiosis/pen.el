(defun pen-oob (s)
  "Replace all vowels with 'oob'"

  ;; TODO Improve this by taking into account 'y'
  ;; Phoenetic vowels are better
  ;; Perhaps use an IPA translator
  (replace-regexp-in-string "[aeiou]" "oob" s))

(provide 'pen-fun)