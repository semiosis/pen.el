(defalias '-nth 'nth)
(defalias '-pick-nth 'nth)

;; [[info:elisp#Random Numbers][Emacs Info: elisp#Random Numbers]]

(comment
 (random 50))

(defalias '-random-element 'seq-random-elt)

(provide 'pen-random)
