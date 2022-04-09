(defun pen-term-ranger ()
  (interactive)
  ;; ranger just doesn't look good in term
  ;; (pen-term-nsfa (concat "ranger " (pen-q (current-directory))))
  (pen-nw (concat "ranger " (pen-q (current-directory)))))

(defun pen-spv-ranger ()
  (interactive)
  (shell-command (concat "pen-tm -f -d -te spv -c " (pen-q default-directory) " ranger")))

(defun pen-sps-ranger (dir)
  (interactive (list default-directory))
  (shell-command (concat "pen-tm -f -d -te sps -c " (pen-q dir) " ranger")))
(defalias 'pen-sh/ranger 'pen-sps-ranger)


;;; Now emacs ranger

;; I had to add
;; (hide-mode-line-mode 1)
(defun ranger-preview-buffer (entry-name)
  "Create the preview buffer of `ENTRY-NAME'.  If `ranger-show-literal'
is set, show literally instead of actual buffer."
  (if ranger-show-literal
      ;; show literal version of file
      (let ((temp-buffer (or (get-buffer "*ranger-prev*")
                             (generate-new-buffer "*ranger-prev*"))))
        (with-current-buffer temp-buffer
          (buffer-disable-undo)
          (setq-local cursor-type nil)
          (erase-buffer)
          (font-lock-mode -1)
          (hide-mode-line-mode 1)
          (insert-file-contents entry-name)
          (current-buffer)))
    ;; show file
    ;; (if (image-type-from-file-header entry-name)
    (if (and (image-type-from-file-header entry-name)
             (not (eq (image-type-from-file-header entry-name) 'gif))
             ranger-image-fit-window)
        (ranger-setup-image-preview entry-name)
      (let ((inhibit-modification-hooks t)
            (auto-save-default nil)
            (inhibit-message t))
        (with-current-buffer
            (or
             (find-buffer-visiting entry-name)
             (let ((delay-mode-hooks t)
                   (enable-local-variables nil)
                   ;; don't update recentf list
                   (recentf-list nil))
               (find-file-noselect entry-name t ranger-show-literal)))
          (current-buffer))))))

;; I had to add
;; (hide-mode-line-mode 1)
(defun ranger-dir-contents (entry)
  "Open `ENTRY' in dired buffer."
  (let ((temp-buffer (or (get-buffer "*ranger-prev*")
                         (generate-new-buffer "*ranger-prev*"))))
    (with-demoted-errors
        (with-current-buffer temp-buffer
          (make-local-variable 'font-lock-defaults)
          (setq font-lock-defaults '((dired-font-lock-keywords) nil t))
          (buffer-disable-undo)
          (setq-local cursor-type nil)
          (erase-buffer)
          (turn-on-font-lock)
          (insert-directory entry (concat dired-listing-switches ranger-sorting-switches) nil t)
          (goto-char (point-min))
          ;; truncate lines in directory buffer
          (ranger-truncate)
          (hide-mode-line-mode 1)
          ;; (visual-line-mode nil)
          ;; remove . and .. from directory listing
          (save-excursion
            (while (re-search-forward "total used in directory\\|\\.$" nil t)
              ;; (beginning-of-line)
              (delete-region (progn (forward-line 0) (point))
                             (progn (forward-line 1) (point)))))
          (current-buffer)))))

;; I had to subtract 1 more from =space=
(defun ranger-details-message (&optional sizes)
  "Echo file details."
  (when (dired-get-filename nil t)
    (let* ((entry (dired-get-filename nil t))
           ;; enable to troubleshoot speeds
           ;; (sizes t)
           (filename (file-name-nondirectory entry))
           (fattr (file-attributes entry))
           (fwidth (frame-width))
           (file-size (if sizes (concat "File "
                                        (file-size-human-readable (nth 7 fattr))) "Press \'du\' for size info."))
           (dir-size (if sizes (concat "Dir " (ranger--get-file-sizes
                                               (ranger--get-file-listing
                                                dired-directory)
                                               ;; (list dired-directory)
                                               ))
                       ""))
           (user (nth 2 fattr))
           (file-mount
            (if sizes
                (or (let ((index 0)
                          size
                          return)
                      (dolist (mount (ranger--get-mount-partitions 'mount)
                                     return)
                        (when (string-match (concat "^" mount "/.*") entry)
                          (setq size
                                (nth index
                                     (ranger--get-mount-partitions 'avail)))
                          (setq return (format "%s free (%s)" size mount)))
                        (setq index (+ index 1))
                        ))
                    "") ""))
           (filedir-size (if sizes (ranger--get-file-sizes
                                    (ranger--get-file-listing dired-directory))
                           ""))
           (file-date (format-time-string "%Y-%m-%d %H:%m"
                                          (nth 5 fattr)))
           (file-perm (nth 8 fattr))
           (cur-pos (- (get-current-line-string-number-at-pos (point)) 1))
           (final-pos (- (get-current-line-string-number-at-pos (point-max)) 2))
           (position (format "%3d/%-3d"
                             cur-pos
                             final-pos))
           (footer-spec (ranger--footer-spec))
           (lhs (format
                 " %s %s"
                 (propertize file-date 'face 'font-lock-warning-face)
                 file-perm))
           (rhs (format
                 "%s %s %s %s"
                 file-size
                 dir-size
                 file-mount
                 position
                 ))
           (fringe-gap (if (or (eq fringe-mode 0)
                               (eq (cdr-safe fringe-mode) 0)
                               (eq (car-safe fringe-mode) 0)) 1 0))
           (space (- fwidth
                     fringe-gap
                     (length lhs)
                     1))
           (message-log-max nil)
           (msg
            (format
             ;; "%s"
             (format  "%%s%%%ds" space)
             lhs
             rhs
             )))
      (message "%s" msg))))

(setq ranger--debug t)
(setq ranger--debug nil)

(defun ranger-find-file (&optional entry ignore-history)
  "Find file in ranger buffer.  `ENTRY' can be used as path or filename, else will use
currently selected file in ranger. `IGNORE-HISTORY' will not update history-ring on change"
  (interactive)
  (let ((find-name (or entry
                       (dired-get-filename nil t)))
        (minimal (r--fget ranger-minimal))
        (bname (buffer-file-name (current-buffer))))
    (when find-name
      (if (file-directory-p find-name)
          (progn
            (ranger--message "opening directory: %s" find-name)
            (ranger-save-window-settings)
            (ranger--message "settings saved: %s" find-name)
            (unless ignore-history
              (ranger-update-history find-name))
            (advice-add 'dired-readin :after #'ranger-setup-dired-buffer)
            (switch-to-buffer
             ;; TODO make separate buffer of directory if more than one already exists.
             (or (car (or (dired-buffers-for-dir find-name) ()))
                 (dired-noselect find-name)))
            ;; (call-interactively 'ranger-next-file)
            ;; (call-interactively 'ranger-prev-file)
            ;; select origination file
            (when (and bname (file-exists-p bname))
              (dired-goto-file bname))
            ;; reset minimal setting
            (if minimal
                (r--fset ranger-minimal t)
              (r--fset ranger-minimal nil))
            (ranger-parent-child-select)
            (ranger--message "setting up ranger windows: %s" find-name)
            (ranger-mode)

            ;; This appears to have fixed the issue with displaying the first thing when entering a directory
            (call-interactively 'ranger-next-file)
            (call-interactively 'ranger-prev-file)
            (ranger--message "DONE")
            ;; (dired-unadvertise find-name)
            )
        (progn
          (ranger--message "opening file: %s" find-name)
          (find-file find-name)
          (ranger-still-dired))))))

(defun ranger-tpreview (fp)
  (interactive (list ranger-current-file))
  (pen-sn (pen-cmd "tpreview" fp)))

(defun pen-ranger-to-dired ()
  (interactive)
  (let ((dir (get-dir)))
    (call-interactively 'ranger-close)
    (dired dir)))

(defun ranger-around-advice (proc &rest args)
  (let* ((path (car args))
         (res (apply proc (list (if path (pen-umn path))))))
    res))
(advice-add 'ranger :around #'ranger-around-advice)

(remove-hook 'dired-mode-hook 'ranger-set-dired-key)

(defun get-scope-for-file (fp)
  (pen-cl-sn (concat "pen-scope.sh -t " (pen-q fp)) :chomp t))

(defun ranger-preview-buffer (entry-name)
  "Create the preview buffer of `ENTRY-NAME'.  If `ranger-show-literal'
is set, show literally instead of actual buffer."
  (if ranger-show-literal
      ;; show literal version of file
      (let ((temp-buffer (or (get-buffer "*ranger-prev*")
                             (generate-new-buffer "*ranger-prev*"))))
        (with-current-buffer temp-buffer
          (buffer-disable-undo)
          (setq-local cursor-type nil)
          (erase-buffer)
          (font-lock-mode -1)
          (insert (get-scope-for-file entry-name))
          (current-buffer)))
    (if (and (image-type-from-file-header entry-name)
             (not (eq (image-type-from-file-header entry-name) 'gif))
             ranger-image-fit-window)
        (ranger-setup-image-preview entry-name)
      (let ((inhibit-modification-hooks t)
            (auto-save-default nil)
            (inhibit-message t))
        (with-current-buffer
            (or
             (find-buffer-visiting entry-name)
             (let ((delay-mode-hooks t)
                   (enable-local-variables nil)
                   ;; don't update recentf list
                   (recentf-list nil))
               (find-file-noselect entry-name t ranger-show-literal)))
          (current-buffer))))))

(define-key ranger-mode-map (kbd "s") 'sph)
(define-key ranger-mode-map (kbd "S") 'spv)
(define-key ranger-mode-map (kbd "v") nil)
(define-key ranger-mode-map (kbd "V") 'ranger-toggle-marks)
(define-key ranger-mode-map (kbd "M-v") 'dired-view-file-v)
(define-key ranger-mode-map (kbd "M-V") 'dired-view-file-vs)
(define-key ranger-mode-map (kbd "<next>") 'ranger-half-page-down)
(define-key ranger-mode-map (kbd "<prior>") 'ranger-half-page-up)
(define-key ranger-mode-map (kbd "M-^") 'vc-cd-top-level)
(define-key ranger-mode-map (kbd "r") 'pen-ranger-to-dired)
(define-key ranger-mode-map (kbd "M-r") 'sps-ranger)
(define-key ranger-mode-map (kbd "M-1") 'ranger-tpreview)

(define-key global-map (kbd "M-R") 'ranger)
(define-key global-map (kbd "M-E") 'ranger)

(provide 'pen-ranger)
