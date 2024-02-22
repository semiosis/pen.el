;; * TODO For Bible-mode, have a far-right margin like what magit-log has
;; j:magit-log-format-author-margin
;; Nice! I got it going!

;; ** Set this variable locally
(comment
 (defvar-local magit-buffer-margin '(t age 30 t 18))
 (make-local-variable 'magit-buffer-margin)
 (setq magit-buffer-margin '(t age 30 t 18)))

;; Then inside the buffer, toggle the margin on and off
;; mx:magit-toggle-margin

;; ** DONE Extend this to do any mode:

(defset bible-mode-margin
        '(t age magit-log-margin-width t 18))

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
    ('bible-mode 'bible-mode-margin)
    ;; I need to force-disable it now for certain modes in magit that did not use it
    ('magit-diff-mode nil)
    (_ 'magit-log-margin)))

(defsetface pen-magit-right-margin-face
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline nil))
  "Read right margin face."
  :group 'pen-faces)

(defun pen-magit-make-margin-overlay (&optional string previous-line)
  (if previous-line
      (save-excursion
        (forward-line -1)
        (magit-make-margin-overlay string))
    ;; Don't put the overlay on the complete line to work around #1880.
    (let ((o (make-overlay (1+ (line-beginning-position))
                           (line-end-position)
                           nil t)))
      (overlay-put o 'evaporate t)
      (overlay-put o 'before-string
                   (propertize "o"
                               ;; 'face 'pen-magit-right-margin-face
                               'display (list (list 'margin 'right-margin) (or string " ")))))))

;; This adds a line
(comment
 (let ((magit-buffer-margin '(t age 30 t 18)))
   ;; This is sufficient
   (magit-make-margin-overlay "Something cool")

   ;; This has some colour
   ;; (magit-log-format-author-margin "Shane Mulligan" "1705809014")
   ))

(defun magit-margin-on ()
  (interactive)

  (if magit-buffer-margin
      (progn
        (setcar magit-buffer-margin nil)
        (magit-toggle-margin))))

(defun magit-margin-off ()
  (interactive)

  (if magit-buffer-margin
      (progn
        (setcar magit-buffer-margin t)
        (magit-toggle-margin))))

(provide 'pen-magit-margin)
