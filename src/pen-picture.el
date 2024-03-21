(require 'artist)

;; j:artist-draw-sline

(require 'picture)

(defun toggle-picture-mode ()
  (interactive)
  (if (eq major-mode 'picture-mode)
      (picture-mode-exit)
    (picture-mode)))

(provide 'pen-picture)
