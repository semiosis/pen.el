;; * TODO For Bible-mode, have a far-right margin like what magit-log has
;; j:magit-log-format-author-margin
;; Nice! I got it going!

;; ** Set this variable locally
(comment
 (defvar-local magit-buffer-margin '(t age 30 t 18))
 (make-local-variable 'magit-buffer-margin)
 (setq magit-buffer-margin '(t age 30 t 18)))

;; Then inside the buffer, toggle the margin on
;; mx:magit-toggle-margin

;; ** DONE Extend this to do any mode:

(defun magit-margin-option ()
  (pcase major-mode
    ('magit-cherry-mode 'magit-cherry-margin)
    ('magit-log-mode 'magit-log-margin)
    ('magit-log-select-mode 'magit-log-select-margin)
    ('magit-reflog-mode 'magit-reflog-margin)
    ('magit-refs-mode 'magit-refs-margin)
    ('magit-stashes-mode 'magit-stashes-margin)
    ('magit-status-mode 'magit-status-margin)
    ('forge-notifications-mode 'magit-status-margin)
    ;; This is how I extend it
    (_ 'magit-log-margin)))

;; This adds a line
(comment
 (let ((magit-buffer-margin '(t age 30 t 18)))
   (magit-log-format-author-margin "Shane Mulligan" "1705809014")))

(provide 'pen-magit-margin)
