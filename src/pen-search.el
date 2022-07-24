(defun isearch-forward-region-cleanup ()
  "turn off variable, widen"
  (if isearch-forward-region
      (widen))
  (setq isearch-forward-region nil))

(defvar isearch-forward-region nil
  "variable used to indicate we're in region search")

(add-hook 'isearch-mode-end-hook 'isearch-forward-region-cleanup)

(defun isearch-forward-region (&optional regexp-p no-recursive-edit)
  "Do an isearch-forward, but narrow to region first."
  (interactive "P\np")
  (if (pen-selected-p)
      (progn
        (narrow-to-region (point) (mark))
        (deactivate-mark)
        (goto-char (point-min))
        (setq isearch-forward-region t)
        (isearch-mode t (not (null regexp-p)) nil (not no-recursive-edit)))
    (call-interactively 'pen-isearch-forward)))

(define-key global-map (kbd "C-s") #'isearch-forward-region)

;; Not sure if works
(defmacro save-region-excursion (&rest body)
  `(pen-with-advice
       (advise-to-save-region)
     ,@body))

(provide 'pen-isearch)
