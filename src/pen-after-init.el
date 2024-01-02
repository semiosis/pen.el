;; For some reason, it wasn't loading properly
(add-hook 'after-init-hook (lambda () (load-library "pen-org-agenda")))

;; Why isn't this working?
;; (add-hook 'after-make-frame-functions (lambda (frame) (load-library "pen-org-link-types")))

(defun after-init-loads ()
  (interactive)
  (load-library "ol-info")
  (load-library "pen-org-link-types"))

(add-hook 'after-init-hook 'after-init-loads)

(provide 'pen-after-init)
