(require 'pcase)

;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Extending-pcase.html

(pcase-defmacro re (pat)
  "Matches if EXPVAL is a regex matching pat."
  `(and (pred stringp)
        (pred (lambda (s) (re-match-p ,pat s)))))

;; https://www.reddit.com/r/emacs/comments/nlq71/does_anyone_know_how_to_use_pcaseel_in_emacs_24/

(comment

 ;; Can I capture from the echo area?
 ;; [[info:emacs#Echo Area][Emacs Info: emacs#Echo Area]]
 
 (dolist (triple (list '(3 0 3) '(1 2 3) '(1 1 1)))
   (princ triple)
   (princ ": ")
   (pcase triple
     (`(,a ,a ,a)
      (princ (format "%S is repeated trice." a)))
     (`(,a ,b ,a)
      (princ (format "%S is surrounded by %S." b a)))
     (_
      (princ (format "Nothing to see here."))))
   (terpri))

 (dolist (x (list '("A" . "B") '(1 . 2)))
   (pcase-let ((`(,a . ,b) x))
     (princ `(,b . ,a))
     (terpri))))

(provide 'pen-pcase)
