;; Make it so I can easily call from a list of functions mapped to a single key binding
;; This is useful for when, say, I need to call a function from a key binding instead of through the eval-expression repl,
;; but this is just for developing the function, not for normal use.

(defset function-dev-exprs '(
                             (completing-read "Menu item: " '("a" "b" "c") nil t nil nil nil nil)
                             (completing-read "Menu item: " '("a" "b" "c") nil t nil nil "" nil)
                             (ivy-completing-read "Menu item: " '("a" "b" "c") nil t nil nil nil nil)
                             (ivy-completing-read "Menu item: " '("a" "b" "c") nil t nil nil "" nil)))

(defun function-dev-run-expr ()
  (interactive)
  (let* ((s (fz (mapcar 'pp-oneline function-dev-exprs) nil nil "function-dev-run-expr: "))
         (l (eval-string (concat "'" s)))
         (f (eval `(lambda () (interactive) ,l))))
    
    (if f
        (call-interactively f))))

(define-key global-map (kbd "s-s") 'function-dev-run-expr)

(provide 'pen-function-dev)
