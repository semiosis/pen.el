;; e:/usr/local/share/emacs/29.4.50/lisp/files.el.gz

;; (setq remote-shell-program "/usr/bin/ssh")
(setq remote-shell-program "ssh")

;; Derived from j:set-auto-mode--apply-alist
(defun get-mode-for-file (fp &optional alist)
  "This function takes an alist of the same form as
`auto-mode-alist'.  It then tries to find the appropriate match
in the alist for the current buffer; returning the mode if
possible.
Return non-nil if the mode was set, nil otherwise.
DIR-LOCAL non-nil means this call is via directory-locals, and
extra checks should be done."
  (let (mode
        (alist (or alist auto-mode-alist))
        (name fp)
        (remote-id (file-remote-p fp))
        (case-insensitive-p (file-name-case-insensitive-p
                             fp)))
    ;; Remove backup-suffixes from file name.
    (setq name (file-name-sans-versions name))
    ;; Remove remote file name identification.
    (when (and (stringp remote-id)
               (string-match (regexp-quote remote-id) name))
      (setq name (substring name (match-end 0))))
    (while name
      ;; Find first matching alist entry.
      (setq mode
            (if case-insensitive-p
                ;; Filesystem is case-insensitive.
                (let ((case-fold-search t))
                  (assoc-default name alist 'string-match))
              ;; Filesystem is case-sensitive.
              (or
               ;; First match case-sensitively.
               (let ((case-fold-search nil))
                 (assoc-default name alist 'string-match))
               ;; Fallback to case-insensitive match.
               (and auto-mode-case-fold
                    (let ((case-fold-search t))
                      (assoc-default name alist 'string-match))))))
      (if (and mode
               (not (functionp mode))
               (consp mode)
               (cadr mode))
          (setq mode (car mode)
                name (substring name 0 (match-beginning 0)))
        (setq name nil)))
    ;; (when (and dir-local mode
    ;;            (not (set-auto-mode--dir-local-valid-p mode)))
    ;;   (message "Ignoring invalid mode `%s'" mode)
    ;;   (setq mode nil))

    mode
    ;; (when mode
    ;;   (set-auto-mode-0 mode keep-mode-if-same)
    ;;   t)
    ))

(comment
 (get-mode-for-file "yo.yuv")
 (get-mode-for-file "README.org"))

(provide 'pen-files)
