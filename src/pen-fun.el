;; Language games

(defun pen-oob (s)
  "Replace all vowels with 'oob'"

  ;; TODO Improve this by taking into account 'y'
  ;; Phoenetic vowels are better
  ;; Perhaps use an IPA translator
  (replace-regexp-in-string "[aeiou]" "oob" s))

(defun pen-oob-test ()
  (interactive)
  (pen-etv (pen-oob "To be or not to be, that is the question.")))

(defun pen-piglatin-word (w)
  (cond
   ((string-match "^[aeiou]" w) (concat w "yay"))
   ((string-match "^[^aeiou]" w) (concat w "yay"))))

(defun pen-piglatin (s)
  "If a word begins with a vowel, just add \"yay\" to the end. For example, \"out\" is translated into \"outyay\".
If it begins with a consonant, then we take all consonants before the first vowel and we put them on the end of the word.
For example, \"which\" is translated into \"ichwhay\".")

(provide 'pen-fun)