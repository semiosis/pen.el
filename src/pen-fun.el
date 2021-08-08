(defun pen-oob (s)
  "Replace all vowels with 'oob'"

  ;; TODO Improve this by taking into account 'y'
  ;; Phoenetic vowels are better
  ;; Perhaps use an IPA translator
  (replace-regexp-in-string "[aeiou]" "oob" s))

(defun pen-oob-test ()
  (interactive)
  (etv (pen-oob "To be or not to be, that is the question.")))

(provide 'pen-fun)