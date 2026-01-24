;; * TODO Figure out how to do more types of text searches which I can't do with regex - and then consider making a DSL for it
;; For example:
;; - Find all instances of a regex match followed by another regex match followed by another regex match, but all 3 matches need to be within consecutive lines
;;   - I should probably use emacs lisp for these types of tasks, because I can work with a buffer and can make use of other DSLs from elisp
;;     - OK, so I need to maintain a library of text search functions

;; ** TODO Set up e:pen-e to facilitate this

;; - Use =-E-tcp-echo=

(provide 'pen-strings)
