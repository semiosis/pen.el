(require 'cua-base)
(require 'lispy)

(defun pen-lispy-paste ()
  (interactive)
  (xc (pen-mnm (xc nil t t)) t t)
  (call-interactively 'lispy-yank))

(defun pen-paste ()
  (interactive)
  (xc (pen-mnm (xc nil t t)) t t)
  (call-interactively 'cua-paste))

(defun cua-paste-around-advice (proc &rest args)
  (xc (pen-mnm (xc nil t)) t)
  (let ((res (apply proc args)))
    res))
(advice-add 'cua-paste :around #'cua-paste-around-advice)

(define-key lispy-mode-map (kbd "C-y") 'pen-lispy-paste)

(provide 'pen-paste)