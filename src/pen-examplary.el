(defmacro defprompt (&rest body)
  ""
  `(progn ,@body))

(defprompt lines->regex
  :e "grex"
  "example 1\nexample2" "^example [12]$"
  "example 2\nexample3" "^example [23]$"
  "pi4\npi5" "^pi[45]$")


(provide 'examplary)