;; e:/usr/local/share/emacs/29.4.50/lisp/files.el.gz

;; (setq remote-shell-program "/usr/bin/ssh")
(setq remote-shell-program "ssh")

(require 'files)

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

(defun get-mode-for-ext (ext &optional alist)
  (get-mode-for-file (concat "mantissa." ext)))

(comment
 (get-mode-for-file "yo.yuv")
 (get-mode-for-file "README.org"))

(defun files--ask-user-about-large-file (size op-type filename offer-raw)
  "Query the user about what to do with large files.
Files are \"large\" if file SIZE is larger than `large-file-warning-threshold'.

OP-TYPE specifies the file operation being performed on FILENAME.

If OFFER-RAW is true, give user the additional option to open the
file literally."
  (let ((prompt (format "File %s is large (%s), really %s?"
                        (file-name-nondirectory filename)
                        (funcall byte-count-to-string-function size) op-type)))
    (if (not offer-raw)
        (if (y-or-n-p prompt) nil 'abort)
      (let ((choice
             (car
              (read-multiple-choice
               prompt '((?y "yes")
                        (?n "no")
                        (?l "literally")
                        (?f "in fundamental-mode")
                        (?m "select a major mode"))
               (files--ask-user-about-large-file-help-text
                op-type (funcall byte-count-to-string-function size))))))
        (cond ((eq choice ?y) nil)
              ((eq choice ?l) 'raw)
              ((eq choice ?f) 'fff)
              ((eq choice ?m)
               (let ((subchoice (car
                                 (read-multiple-choice
                                  "Major mode: " '((?t "text-mode")
                                                   (?h "help-mode")
                                                   (?o "outline-mode")
                                                   (?s "org-strippeddown-mode"))))))
                 (cond ((eq subchoice ?t) 'text-mode)
                       ((eq subchoice ?h) 'help-mode)
                       ((eq subchoice ?o) 'outline-mode)
                       ((eq subchoice ?s) 'org-strippeddown-mode))))
              ((eq choice ?z) (str2sym (fz (list 'text-mode
                                                 'help-mode
                                                 'outline-mode
                                                 'org-strippeddown-mode)
                                           nil nil "Major mode: ")))
              (t 'abort))))))

(defun abort-if-file-too-large (size op-type filename &optional offer-raw)
  "If file SIZE larger than `large-file-warning-threshold', allow user to abort.
OP-TYPE specifies the file operation being performed (for message
to user).  If OFFER-RAW is true, give user the additional option
to open the file literally.  If the user chooses this option,
`abort-if-file-too-large' returns the symbol `raw'.  Otherwise,
it returns nil or exits non-locally."
  (let ((choice (and large-file-warning-threshold size
	             (> size large-file-warning-threshold)
                     ;; No point in warning if we can't read it.
                     (file-readable-p filename)
                     (files--ask-user-about-large-file
                      size op-type filename offer-raw))))
    (when (eq choice 'abort)
      (user-error "Aborted"))
    choice))

(defun find-file-noselect (filename &optional nowarn rawfile wildcards)
  "Read file FILENAME into a buffer and return the buffer.
If a buffer exists visiting FILENAME, return that one, but
verify that the file has not changed since visited or saved.
The buffer is not selected, just returned to the caller.
Optional second arg NOWARN non-nil means suppress any warning messages.
Optional third arg RAWFILE non-nil means the file is read literally.
Optional fourth arg WILDCARDS non-nil means do wildcard processing
and visit all the matching files.  When wildcards are actually
used and expanded, return a list of buffers that are visiting
the various files."
  ;; (tv rawfile)
  (setq filename
        (abbreviate-file-name
         (expand-file-name filename)))
  (if (file-directory-p filename)
      (or (and find-file-run-dired
               (run-hook-with-args-until-success
                'find-directory-functions
                (if find-file-visit-truename
                    (abbreviate-file-name (file-truename filename))
                  filename)))
          (error "%s is a directory" filename))
    (if (and wildcards
             find-file-wildcards
             (not (file-name-quoted-p filename))
             (string-match "[[*?]" filename))
        (let ((files (condition-case nil
                         (file-expand-wildcards filename t)
                       (error (list filename))))
              (find-file-wildcards nil))
          (if (null files)
              (find-file-noselect filename)
            (mapcar #'find-file-noselect files)))
      (let* ((buf (get-file-buffer filename))
             (truename (abbreviate-file-name (file-truename filename)))
             (attributes (file-attributes truename))
             (number (file-attribute-file-identifier attributes))
             ;; Find any buffer for a file that has same truename.
             (other (and (not buf)
                         (find-buffer-visiting
                          filename
                          ;; We want to filter out buffers that we've
                          ;; visited via symlinks and the like, where
                          ;; the symlink no longer exists.
                          (lambda (buffer)
                            (let ((file (buffer-local-value
                                         'buffer-file-name buffer)))
                              (and file (file-exists-p file))))))))
        ;; Let user know if there is a buffer with the same truename.
        (when other
          (or nowarn
              find-file-suppress-same-file-warnings
              (string-equal filename (buffer-file-name other))
              (files--message "%s and %s are the same file"
                              filename (buffer-file-name other)))
          ;; Optionally also find that buffer.
          (if (or find-file-existing-other-name find-file-visit-truename)
              (setq buf other)))
        ;; Check to see if the file looks uncommonly large.
        (when (not (or buf nowarn))
          (setf rawfile (or rawfile
                            (abort-if-file-too-large
                             (file-attribute-size attributes) "open" filename
                             (not rawfile))))
          (warn-maybe-out-of-memory (file-attribute-size attributes)))
        (if buf
            ;; We are using an existing buffer.
            (let (nonexistent)
              (or nowarn
                  (verify-visited-file-modtime buf)
                  (cond ((not (file-exists-p filename))
                         (setq nonexistent t)
                         (message "File %s no longer exists!" filename))
                        ;; Certain files should be reverted automatically
                        ;; if they have changed on disk and not in the buffer.
                        ((and (not (buffer-modified-p buf))
                              (let ((tail revert-without-query)
                                    (found nil))
                                (while tail
                                  (if (string-match (car tail) filename)
                                      (setq found t))
                                  (setq tail (cdr tail)))
                                found))
                         (with-current-buffer buf
                           (message "Reverting file %s..." filename)
                           (revert-buffer t t)
                           (message "Reverting file %s...done" filename)))
                        ((not query-about-changed-file)
                         (message
                          (substitute-command-keys
                           "File %s changed on disk.  \\[revert-buffer-quick] to load new contents%s")
                          (file-name-nondirectory filename)
                          (if (buffer-modified-p buf)
                              " and discard your edits"
                            "")))
                        ((yes-or-no-p
                          (if (string= (file-name-nondirectory filename)
                                       (buffer-name buf))
                              (format
                               (if (buffer-modified-p buf)
                                   "File %s changed on disk.  Discard your edits? "
                                 "File %s changed on disk.  Reread from disk? ")
                               (file-name-nondirectory filename))
                            (format
                             (if (buffer-modified-p buf)
                                 "File %s changed on disk.  Discard your edits in %s? "
                               "File %s changed on disk.  Reread from disk into %s? ")
                             (file-name-nondirectory filename)
                             (buffer-name buf))))
                         (with-current-buffer buf
                           (revert-buffer t t)))))
              (with-current-buffer buf

                ;; Check if a formerly read-only file has become
                ;; writable and vice versa, but if the buffer agrees
                ;; with the new state of the file, that is ok too.
                (let ((read-only (not (file-writable-p buffer-file-name))))
                  (unless (or nonexistent
                              (eq read-only buffer-file-read-only)
                              (eq read-only buffer-read-only))
                    (when (or nowarn
                              (let* ((new-status
                                      (if read-only "read-only" "writable"))
                                     (question
                                      (format "File %s is %s on disk.  Make buffer %s, too? "
                                              buffer-file-name
                                              new-status new-status)))
                                (y-or-n-p question)))
                      (setq buffer-read-only read-only)))
                  (setq buffer-file-read-only read-only))

                (unless (or (eq (null rawfile) (null find-file-literally))
                            nonexistent
                            ;; It is confusing to ask whether to visit
                            ;; non-literally if they have the file in
                            ;; hexl-mode or image-mode.
                            (memq major-mode '(hexl-mode image-mode)))
                  (if (buffer-modified-p)
                      (if (let ((help-form
                                 (format-message
                                  (cond
                                   ((eq rawfile 'fff)
                                    "\
The file %s is already visited normally,
and you have edited the buffer.  Now you have asked to visit it in fundamental-mode. Emacs can visit a file in only one way at a time.")
                                   ((symbol-function rawfile)
                                    (concat "\
The file %s is already visited normally,
and you have edited the buffer.  Now you have asked to visit it in " (str rawfile) ". Emacs can visit a file in only one way at a time."))
                                   (rawfile
                                    "\
The file %s is already visited normally,
and you have edited the buffer.  Now you have asked to visit it literally,
meaning no coding system handling, format conversion, or local variables.
Emacs can visit a file in only one way at a time.")
                                   (t
                                    "\
The file %s is already visited literally,
meaning no coding system handling, format conversion, or local variables.
You have edited the buffer.  Now you have asked to visit the file normally,
but Emacs can visit a file in only one way at a time."))
                                  (file-name-nondirectory filename)
                                  )))
                            (y-or-n-p
                             (if rawfile
                                 (cond
                                  ((eq rawfile 'fff)
                                   "\
Do you want to save the file, and visit it in fundamental-mode instead? ")
                                  ((symbol-function rawfile)
                                   (concat "\
Do you want to save the file, and visit it in " (str rawfile) "  instead? "))
                                  (rawfile
                                   "\
Do you want to save the file, and visit it literally instead? ")
                                  (t
                                   "\
Do you want to save the file, and visit it normally instead? ")))))
                          (progn
                            (save-buffer)

                            (cond
                             ((eq rawfile 'fff)
                              (let ((auto-mode-alist nil))
                                (find-file-noselect-1 buf filename nowarn
                                                      nil truename number)))
                             ((symbol-function rawfile)
                              (let ((auto-mode-alist nil))
                                (find-file-noselect-1 buf filename nowarn
                                                      nil truename number)
                                (with-current-buffer buf
                                  (call-interactively rawfile)
                                  buf)))
                             (rawfile
                              (find-file-noselect-1 buf filename nowarn
                                                    t truename number))
                             (t
                              ;; This case shouldn't be reached.
                              ;; It's when rawfile is nil.
                              nil)))
                        (if (y-or-n-p
                             (cond
                              ((eq 'raw rawfile)
                               "\
Do you want to discard your changes, and visit the file literally now? ")
                              ((eq 'fff rawfile)
                               "\
Do you want to discard your changes, and visit the file in fundamental-mode now? ")
                              (t "\
Do you want to discard your changes, and visit the file normally now? ")))
                            (cond
                             ((eq 'raw rawfile)
                              (find-file-noselect-1 buf filename nowarn
                                                    t truename number))
                             ((eq 'fff rawfile)
                              (let ((auto-mode-alist nil))
                                (find-file-noselect-1 buf filename nowarn
                                                      nil truename number)))
                             ((symbol-function rawfile)
                              (let ((auto-mode-alist nil))
                                (find-file-noselect-1 buf filename nowarn
                                                      nil truename number)
                                (with-current-buffer buf
                                  (call-interactively rawfile)
                                  buf)))
                             (t (find-file-noselect-1 buf filename nowarn
                                                      nil truename number)))
                          (error (if rawfile "File already visited non-literally"
                                   "File already visited literally"))))
                    (if (let ((help-form
                               (cond
                                ((eq rawfile 'fff)
                                 "\
The file %s is already visited normally.
You have asked to visit it in fundamental mode.
But Emacs can visit a file in only one way at a time.")
                                ((symbol-function rawfile)
                                 (concat "\
The file %s is already visited normally.
You have asked to visit it in " (str rawfile) ". Emacs can visit a file in only one way at a time."))
                                (rawfile
                                 "\
The file %s is already visited normally.
You have asked to visit it literally,
meaning no coding system decoding, format conversion, or local variables.
But Emacs can visit a file in only one way at a time.")
                                (t
                                 "\
The file %s is already visited literally,
meaning no coding system decoding, format conversion, or local variables.
You have asked to visit it normally,
but Emacs can visit a file in only one way at a time."))
                               (file-name-nondirectory filename)))
                          
                          
                          
                          (y-or-n-p
                           (cond
                            ((eq 'raw rawfile)
                             "\
Do you want to revisit the file literally now? ")
                            ((eq 'fff rawfile)
                             "\
Do you want to revisit the file in fundamenta-mode now? ")
                            (t "\
Do you want to revisit the file normally now? "))))
                        (cond
                         ((eq 'raw rawfile)
                          (find-file-noselect-1 buf filename nowarn
                                                t truename number))
                         ((eq 'fff rawfile)
                          (let ((auto-mode-alist nil))
                            (find-file-noselect-1 buf filename nowarn
                                                  nil truename number)))
                         ((symbol-function rawfile)
                          (let ((auto-mode-alist nil))
                            (find-file-noselect-1 buf filename nowarn
                                                  nil truename number)
                            (with-current-buffer buf
                              (call-interactively rawfile)
                              buf)))
                         (t (find-file-noselect-1 buf filename nowarn
                                                  nil truename number)))
                      (error (if rawfile "File already visited non-literally"
                               "File already visited literally"))))))
              ;; Return the buffer we are using.
              buf)
          ;; Create a new buffer.
          (setq buf (create-file-buffer filename))
          ;; find-file-noselect-1 may use a different buffer.
          (cond
           ((eq 'raw rawfile)
            (find-file-noselect-1 buf filename nowarn
                                  t truename number))
           ((eq 'fff rawfile)
            (let ((auto-mode-alist nil))
              (find-file-noselect-1 buf filename nowarn
                                    nil truename number)))
           ((symbol-function rawfile)
            (let ((auto-mode-alist nil))
              (find-file-noselect-1 buf filename nowarn
                                    nil truename number)
              (with-current-buffer buf
                (call-interactively rawfile)
                buf)))
           (t (find-file-noselect-1 buf filename nowarn
                                    nil truename number))))))))

(provide 'pen-files)
