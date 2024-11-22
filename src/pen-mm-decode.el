(require 'mm-decode)
(require 'mailcap)

;; j:mm-display-part

;; [[ev:mailcap--computed-mime-data]]

;; j:mailcap-mime-info

;; Temporarily wrap the function call with `mm-enable-external` equal to nil if I want to
;; save rather than open, for example, in notmuch.
(setq mm-enable-external t)

(defun mailcap-mime-info-around-advice (proc string &optional request no-decode)
  ;; (tv string)
  (if request
      (let ((res (apply proc (list string request no-decode))))
        res)
    (cond
     ((string-equal "application/pdf" string)
      ;; "zathura %s"
      ;; "pl %s | store-file-by-hash | xa unbuffer sps o"
      "unbuffer sps o %s")
     (t (let ((res (apply proc (list string request no-decode))))
          res)))
    (cond
     ((string-equal "text/html" string)
      ;; "zathura %s"
      ;; "pl %s | store-file-by-hash | xa unbuffer sps o"
      "unbuffer sps o %s")
     (t (let ((res (apply proc (list string request no-decode))))
          res)))))
(advice-add 'mailcap-mime-info :around #'mailcap-mime-info-around-advice)
;; (advice-remove 'mailcap-mime-info #'mailcap-mime-info-around-advice)

;; (load-library "mm-decode")
;; Modify this so that the temporary directory name is idempotent.
;; j:mm-display-external

;; j:mm-mailcap-command

;; Move the file to an idempotent directory based on its hash
(defun mm-mailcap-command-around-advice (proc method file type-list)
  (let* ((o_fp file)
         (fn (f-basename file))
         (fp_sha (snc (cmd "sha" "-f" o_fp)))
         (store_dir (f-join (umn "$PEN/file-store-by-hash") fp_sha))
         (ret (mkdir-p store_dir))
         (n_fp (f-join store_dir fn)))

    (if (not (f-exists-p n_fp))
        (f-copy o_fp n_fp))

    (setq file n_fp)

    (let ((res (apply proc (list method file type-list))))
      file
      res)))
(advice-add 'mm-mailcap-command :around #'mm-mailcap-command-around-advice)
;; (advice-remove 'mm-mailcap-command #'mm-mailcap-command-around-advice)

(defun mm-display-external (handle method)
  "Display HANDLE using METHOD."
  ;; (tv (mm-handle-type handle))
  ;; (tv (mm-handle-type handle))
  (let ((outbuf (current-buffer)))
    (mm-with-unibyte-buffer
      (if (functionp method)
          (let ((cur (current-buffer)))
            (if (eq method 'mailcap-save-binary-file)
                (progn
                  (set-buffer (generate-new-buffer " *mm*"))
                  (setq method nil))
              (mm-insert-part handle)
              (mm-add-meta-html-tag handle)
              (let ((win (get-buffer-window cur t)))
                (when win
                  (select-window win)))
              (switch-to-buffer (generate-new-buffer " *mm*")))
            (buffer-disable-undo)
            (set-buffer-file-coding-system mm-binary-coding-system)
            (insert-buffer-substring cur)
            (goto-char (point-min))
            (when method
              (message "Viewing with %s" method))
            (let ((mm (current-buffer))
                  (attachment-filename (mm-handle-filename handle))
                  (non-viewer (assq 'non-viewer
                                    (mailcap-mime-info
                                     (mm-handle-media-type handle) t))))
              (unwind-protect
                  (if method
                      (progn
                        (when (and (boundp 'gnus-summary-buffer)
                                   (buffer-live-p gnus-summary-buffer))
                          (when attachment-filename
                            (with-current-buffer mm
                              (rename-buffer
                               (format "*mm* %s" attachment-filename) t)))
                          ;; So that we pop back to the right place, sort of.
                          (switch-to-buffer gnus-summary-buffer)
                          (switch-to-buffer mm))
                        (funcall method))
                    (mm-save-part handle))
                (when (and (not non-viewer)
                           method)
                  (mm-handle-set-undisplayer handle mm)))))
        ;; The function is a string to be executed.
        (mm-insert-part handle)
        (mm-add-meta-html-tag handle)
        ;; We create a private sub-directory where we store our files.
        (let* ((dir (with-file-modes 448
                      (make-temp-file
                       (expand-file-name "emm." mm-tmp-directory) 'dir)))
               (filename (or
                          (mail-content-type-get
                           (mm-handle-disposition handle) 'filename)
                          (mail-content-type-get
                           (mm-handle-type handle) 'name)))
               (mime-info (mailcap-mime-info
                           (mm-handle-media-type handle) t))
               (needsterm (or (assoc "needsterm" mime-info)
                              (assoc "needsterminal" mime-info)))
               (copiousoutput (assoc "copiousoutput" mime-info))
               file buffer)
          (if filename
              (setq file (expand-file-name
                          (gnus-map-function mm-file-name-rewrite-functions
                                             (file-name-nondirectory filename))
                          dir))
            ;; Use nametemplate (defined in RFC1524) if it is specified
            ;; in mailcap.
            (let ((suffix (cdr (assoc "nametemplate" mime-info))))
              (if (and suffix
                       (string-match "\\`%s\\(\\..+\\)\\'" suffix))
                  (setq suffix (match-string 1 suffix))
                ;; Otherwise, use a suffix according to
                ;; `mailcap-mime-extensions'.
                (setq suffix (car (rassoc (mm-handle-media-type handle)
                                          mailcap-mime-extensions))))
              (setq file (with-file-modes 384
                           (make-temp-file (expand-file-name "mm." dir)
                                           nil suffix)))))
          (let ((coding-system-for-write mm-binary-coding-system))
            (write-region (point-min) (point-max) file nil 'nomesg))
          ;; The file is deleted after the viewer exists.  If the users edits
          ;; the file, changes will be lost.  Set file to read-only to make it
          ;; clear.
          (set-file-modes file 256 'nofollow)
          (message "Viewing with %s" method)
          (cond
           (needsterm
            (let ((command (mm-mailcap-command
                            method file (mm-handle-type handle))))
              (unwind-protect
                  (if window-system
                      (set-process-sentinel
                       (apply #'start-process "*display*" nil
                              (append
                               (if (listp mm-external-terminal-program)
                                   mm-external-terminal-program
                                 ;; Be backwards-compatible.
                                 (list mm-external-terminal-program
                                       "-e"))
                               (list shell-file-name
                                     shell-command-switch
                                     command)))
                       (lambda (process _state)
                         (if (eq 'exit (process-status process))
                             (run-at-time
                              60.0 nil
                              (lambda ()
                                (ignore-errors (delete-file file))
                                (ignore-errors (delete-directory
                                                (file-name-directory
                                                 file))))))))
                    (require 'term)
                    (require 'gnus-win)
                    (set-buffer
                     (setq buffer
                           (make-term "display"
                                      shell-file-name
                                      nil
                                      shell-command-switch command)))
                    (term-mode)
                    (term-char-mode)
                    (set-process-sentinel
                     (get-buffer-process buffer)
                     (let ((wc gnus-current-window-configuration))
                       (lambda (process _state)
                         (when (eq 'exit (process-status process))
                           (ignore-errors (delete-file file))
                           (ignore-errors
                             (delete-directory (file-name-directory file)))
                           (gnus-configure-windows wc)))))
                    (gnus-configure-windows 'display-term))
                (mm-handle-set-external-undisplayer handle (cons file buffer))
                (add-to-list 'mm-temp-files-to-be-deleted file t))
              (message "Displaying %s..." command))
            'external)
           (copiousoutput
            (with-current-buffer outbuf
              (forward-line 1)
              (mm-insert-inline
               handle
               (unwind-protect
                   (progn
                     (call-process shell-file-name nil
                                   (setq buffer
                                         (generate-new-buffer " *mm*"))
                                   nil
                                   shell-command-switch
                                   (mm-mailcap-command
                                    method file (mm-handle-type handle)))
                     (if (buffer-live-p buffer)
                         (with-current-buffer buffer
                           (buffer-string))))
                 (progn
                   (ignore-errors (delete-file file))
                   (ignore-errors (delete-directory
                                   (file-name-directory file)))
                   (ignore-errors (kill-buffer buffer))))))
            'inline)
           (t
            ;; Deleting the temp file should be postponed for some wrappers,
            ;; shell scripts, and so on, which might exit right after having
            ;; started a viewer command as a background job.
            (let ((command (mm-mailcap-command
                            method file (mm-handle-type handle))))
              (unwind-protect
                  (let ((process-connection-type nil))
                    (start-process "*display*"
                                   (setq buffer
                                         (generate-new-buffer " *mm*"))
                                   shell-file-name
                                   shell-command-switch command)
                    (set-process-sentinel
                     (get-buffer-process buffer)
                     (lambda (process _state)
                       (when (eq (process-status process) 'exit)
                         (run-at-time
                          60.0 nil
                          (lambda ()
                            (ignore-errors (delete-file file))
                            (ignore-errors (delete-directory
                                            (file-name-directory file)))))
                         (when (buffer-live-p outbuf)
                           (with-current-buffer outbuf
                             (let ((buffer-read-only nil)
                                   (point (point)))
                               (forward-line 2)
                               (let ((start (point)))
                                 (mm-insert-inline
                                  handle (with-current-buffer buffer
                                           (buffer-string)))
                                 (put-text-property start (point)
                                                    'face 'mm-command-output))
                               (goto-char point))))
                         (when (buffer-live-p buffer)
                           (kill-buffer buffer)))
                       (message "Displaying %s...done" command))))
                (mm-handle-set-external-undisplayer
                 handle (cons file buffer))
                (add-to-list 'mm-temp-files-to-be-deleted file t))
              (message "Displaying %s..." command))
            'external)))))))

(provide 'pen-mm-decode)
