(defun pen-current-time-microseconds ()
  "Return the current time formatted to include microseconds."
  (let* ((nowtime (current-time))
         (now-ms (nth 2 nowtime)))
    (concat (format-time-string "[%Y-%m-%dT%T" nowtime) (format ".%06d]" now-ms))))

(defun pen-ad-timestamp-message (FORMAT-STRING &rest args)
  "Advice to run before `message' that prepends a timestamp to each message.

Activate this advice with:
(advice-add 'message :before 'pen-ad-timestamp-message)"
  (unless (string-equal FORMAT-STRING "%s%s")
    (let ((deactivate-mark nil)
          (inhibit-read-only t))
      (with-current-buffer "*Messages*"
        (save-mark-and-excursion
          (goto-char (point-max))
          (if (not (bolp))
              (newline))
          ;; (ignore-errors (message (concat "LPK: " (last-pressed-key))))
          (insert (pen-current-time-microseconds) " "))))))

(advice-add 'message :before 'pen-ad-timestamp-message)

(defun pen-clear-message ()
  (interactive)
  (message nil))

(defun pen-last-message ()
  (with-current-buffer "*Messages*"
        (save-mark-and-excursion
          (goto-char (point-max))
          (current-line-string))))

(global-set-key (kbd "C-c c") 'pen-clear-message)

;; (defun message-buffer-goto-end-of-buffer (&rest args)
;;   (let* ((win (get-buffer-window "*Messages*"))
;;          (buf (and win (window-buffer win))))
;;     (and win (not (equal (current-buffer) buf))
;;          (set-window-point
;;           win (with-current-buffer buf (point-max))))))

;; (advice-add 'message :after 'message-buffer-goto-end-of-buffer)
;; (advice-remove 'message 'message-buffer-goto-end-of-buffer)

(provide 'pen-messages)
