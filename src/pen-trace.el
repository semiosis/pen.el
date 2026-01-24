(defun pen-trace-function ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (let ((current-prefix-arg nil))   ; C-u
        (call-interactively 'untrace-function))
    (call-interactively 'trace-function)))

(define-key global-map (kbd "s-t") 'pen-trace-function)

(provide 'pen-trace)
