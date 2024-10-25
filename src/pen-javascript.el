(require 'guess-style)

(defun js-guess-and-set-indent-width ()
  (interactive)

  (let ((width (guess-style-guess-indent)))
    (setq js-indent-level width)))

(add-hook 'js-mode-hook 'js-guess-and-set-indent-width)
