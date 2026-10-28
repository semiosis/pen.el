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

(defun pen-last-message ()
  (with-current-buffer "*Messages*"
        (save-mark-and-excursion
          (goto-char (point-max))
          (current-line-string))))

;; (defun message-buffer-goto-end-of-buffer (&rest args)
;;   (let* ((win (get-buffer-window "*Messages*"))
;;          (buf (and win (window-buffer win))))
;;     (and win (not (equal (current-buffer) buf))
;;          (set-window-point
;;           win (with-current-buffer buf (point-max))))))

;; (advice-add 'message :after 'message-buffer-goto-end-of-buffer)
;; (advice-remove 'message 'message-buffer-goto-end-of-buffer)

(defun call-process-around-advice (proc &rest args)
  (message "call-process called with args %S" args)
  (let ((res (apply proc args)))
    (message "call-process returned %S" res)
    res))
(advice-add 'call-process :around #'call-process-around-advice)
(advice-remove 'call-process #'call-process-around-advice)

;; Do it in j:switch-to-messages
;; (add-hook 'messages-buffer-mode-hook 'org-link-minor-mode)

(defun l2-messages-buffer ()
  "Return the \"*Level2-Messages*\" buffer.
If it does not exist, create it and switch it to `messages-buffer-mode'."
  (or (get-buffer "*Level2-Messages*")
      (with-current-buffer (get-buffer-create "*Level2-Messages*")
        (messages-buffer-mode)
        (current-buffer))))

(provide 'pen-messages)
