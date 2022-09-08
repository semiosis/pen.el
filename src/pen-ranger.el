(require 'ranger)

(setq ranger-key nil)

(defun pen-term-ranger ()
  (interactive)
  ;; ranger just doesn't look good in term
  ;; (pen-term-nsfa (concat "ranger " (pen-q (current-directory))))
  (pen-nw (concat "ranger " (pen-q (current-directory)))))

(defun pen-spv-ranger ()
  (interactive)
  (shell-command (concat "pen-tm -f -d -te pen-spv -c " (pen-q default-directory) " ranger")))

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
           (cur-pos (- (line-number-at-pos (point)) 1))
           (final-pos (- (line-number-at-pos (point-max)) 2))
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

(define-key ranger-mode-map (kbd "s") 'pen-sph)
(define-key ranger-mode-map (kbd "S") 'pen-spv)
(define-key ranger-mode-map (kbd "v") nil)
(define-key ranger-mode-map (kbd "V") 'ranger-toggle-marks)
(define-key ranger-mode-map (kbd "M-v") 'dired-view-file-v)
(define-key ranger-mode-map (kbd "M-V") 'dired-view-file-vs)
(define-key ranger-mode-map (kbd "<next>") 'ranger-half-page-down)
(define-key ranger-mode-map (kbd "<prior>") 'ranger-half-page-up)
(define-key ranger-mode-map (kbd "C-u") nil)
(define-key ranger-mode-map (kbd "C-d") nil)
;; new tab
(define-key ranger-mode-map (kbd "C-n") nil)
(define-key ranger-mode-map (kbd "C-p") nil)
(define-key ranger-mode-map (kbd "M-^") 'pen-vc-cd-top-level)
(define-key ranger-mode-map (kbd "r") 'pen-ranger-to-dired)
(define-key ranger-mode-map (kbd "M-r") 'pen-sps-ranger)
(define-key ranger-mode-map (kbd "M-1") 'ranger-tpreview)

(define-key global-map (kbd "M-R") 'ranger)
(define-key global-map (kbd "M-E") 'ranger)

(defun ranger-disable ()
  "Interactively disable ranger-mode."
  (interactive)
  ;; don't kill ranger buffer if open somewhere else
  (if (> (length (get-buffer-window-list)) 1)
      ;; There was a bug in ranger
      (progn
        (delete-window)
        (delete-window ranger-preview-window))
    (ranger-revert)))

;; Sadly, still, ranger crashes, even after adding
;; (set-window-dedicated-p window t)
(defun ranger-setup-parents ()
  "Setup all parent directories."
  (let ((parent-name (ranger-parent-directory default-directory))
        (current-name (expand-file-name default-directory))
        (i 0)
        (unused-windows ()))

    (setq ranger-buffer (current-buffer))

    (setq ranger-window (get-buffer-window (current-buffer)))

    (setq ranger-visited-buffers (append ranger-parent-buffers ranger-visited-buffers))

    (setq ranger-parent-buffers ())
    (setq ranger-parent-windows ())
    (setq ranger-parent-dirs ())

    (unless (r--fget ranger-minimal)
      (while (and parent-name
                  (file-directory-p parent-name)
                  (< i ranger-parent-depth))
        (setq i (+ i 1))
        (unless (string-equal current-name parent-name)
          ;; (walk-window-tree
          ;;  (lambda (window)
          ;;    (when (eq (window-parameter window 'window-slot) (- 0 i))
          ;;      (setq unused-window window)
          ;;      ))
          ;;  nil nil 'nomini)
          (progn
            (add-to-list 'ranger-parent-dirs (cons (cons current-name parent-name) i))
            (setq current-name (ranger-parent-directory current-name))
            (setq parent-name (ranger-parent-directory parent-name)))))
      (mapc 'ranger-make-parent ranger-parent-dirs)

      ;; select child folder in each parent
      (save-excursion
        (walk-window-tree
         (lambda (window)
           (progn
             (when (member window ranger-parent-windows)
               (with-selected-window window
                 (set-window-dedicated-p window t)
                 (ranger-parent-child-select)
                 (ranger-hide-the-cursor)))))
         nil nil 'nomini))

      ;; (select-window ranger-window)
      )))

;; Setting window-dedicated solves the ranger crashes
;; when running term, switching buffers etc.
(defun ranger-sub-window-setup ()
  "Parent window options."
  ;; allow mouse click to jump to that directory
  (setq-local mouse-1-click-follows-link nil)
  (local-set-key (kbd  "<mouse-1>") 'ranger-find-file)
  (set-window-dedicated-p (selected-window) t)
  ;; set header-line
  (when ranger-modify-header
    (setq header-line-format `(:eval (,ranger-header-func)))))

;; I had to add set-window-dedicated-p to this as well
;; Actually, the preview window screws up when going from file to directory
;; while dedicated is set
(comment
 (defun ranger-setup-preview ()
   "Setup ranger preview window."
   (let* ((entry-name (dired-get-filename nil t))
          (window-configuration-change-hook nil)
          (original-buffer-list (buffer-list))
          (inhibit-modification-hooks t)
          (fsize
           (nth 7 (file-attributes entry-name))))
     (when ranger-cleanup-eagerly
       (mapc 'ranger-kill-buffer
             (remove (current-buffer) ranger-preview-buffers))
       (setq ranger-preview-buffers (delq nil ranger-preview-buffers)))
     (when (and (not (r--fget ranger-minimal))
                entry-name
                ranger-preview-file)
       (unless (or
                (> fsize (* 1024 1024 ranger-max-preview-size))
                (member (file-name-extension entry-name)
                        ranger-excluded-extensions))
         (with-demoted-errors "%S"
           (let* ((dir (file-directory-p entry-name))
                  (dired-listing-switches ranger-listing-switches)
                  (preview-buffer (if dir
                                      (ranger-dir-buffer entry-name t)
                                    ;; (ranger-dir-contents entry-name)
                                    (ranger-preview-buffer entry-name)))
                  ;; check for existance of *ranger-prev* buffer
                  (preview-window (and (window-live-p ranger-preview-window)
                                       (eq (selected-frame) (window-frame ranger-preview-window))
                                       ranger-preview-window))
                  )
             (if preview-window
                 (with-selected-window preview-window
                   ;; (set-window-dedicated-p (selected-window) t)
                   (switch-to-buffer preview-buffer))
               (unless (and (not dir) ranger-dont-show-binary (ranger--prev-binary-p))
                 (setq preview-window
                       (display-buffer
                        preview-buffer
                        `(ranger-display-buffer-at-side . ((side . right)
                                                           (slot . 1)
                                                           (inhibit-same-window . t)
                                                           (window-width . ,(- ranger-width-preview
                                                                               (min
                                                                                (- ranger-max-parent-width
                                                                                   ranger-width-parents)
                                                                                (* (- ranger-parent-depth 1)
                                                                                   ranger-width-parents))))))))))
             (with-current-buffer preview-buffer
               (setq-local cursor-type nil)
               (setq-local mouse-1-click-follows-link nil)
               (local-set-key (kbd  "<mouse-1>") #'(lambda ()
                                                     (interactive)
                                                     (select-window ranger-window)
                                                     (call-interactively
                                                      'ranger-find-file)))
               (when ranger-modify-header
                 (setq header-line-format `(:eval (,ranger-header-func))))
               (ranger-hide-the-cursor))
             (when (not (memq preview-buffer original-buffer-list))
               (add-to-list 'ranger-preview-buffers preview-buffer))
             (setq ranger-preview-window preview-window)
             ;; (ranger-hide-details)
             (ranger-hide-details))))))))

;; Tabs have been a problem
(defun ranger-make-tab (index name path)
  (never
   (let ((new-tab (ranger--new-tab :name name :path path)))
     (r--aput ranger-t-alist
              index
              new-tab))))

(defun ranger-hacky-fix ()
  (interactive)

  (setq ranger-w-alist nil)
  (setq ranger-t-alist nil)
  (setq ranger-current-tab nil)
  (setq ranger-undo-tab nil)
  (ranger-close))

(require 'shackle)

;; OK, for starters, the current buffer is the "*Help*" buffer.
;; So, rather, I should be interested int he current window
(defun disable-if-ranger-around-advice (proc &rest args)
  (never (if (-contains? (r--akeys ranger-w-alist)
                         (selected-window))
             (tv (concat (str (selected-window))
                         ":"
                         (str (r--akeys ranger-w-alist))
                         " " (str proc)))))



  ;; This prevents ranger from crashing emacs
  ;; When applied to shackle--window-display-buffer

  ;; However, now shackle just doesn't select things like "*lsp-help*"
  ;; So I need to finish this

  ;; Maybe do a test to see if the window is in
  ;; ranger's window set

  ;; This works, but I also want to abort if it's on the parent directory
  (if (not (-contains? (r--akeys ranger-w-alist)
                       (selected-window)))
      (let ((res (apply proc args)))
        res)))

;; (advice-add 'shackle-display-buffer :around #'disable-if-ranger-around-advice)
;; (advice-add 'shackle--display-buffer :around #'disable-if-ranger-around-advice)
;; (advice-add 'shackle--display-buffer-same :around #'disable-if-ranger-around-advice)
;; (advice-add 'shackle--display-buffer-reuse :around #'disable-if-ranger-around-advice)
;; (advice-remove 'shackle-display-buffer #'disable-if-ranger-around-advice)
;; (advice-remove 'shackle--display-buffer #'disable-if-ranger-around-advice)
;; (advice-remove 'shackle--display-buffer-same #'disable-if-ranger-around-advice)
;; (advice-remove 'shackle--display-buffer-reuse #'disable-if-ranger-around-advice)

;; Is this is the one that breaks it? Yes.
;; It still appears.
(advice-add 'shackle--window-display-buffer :around #'disable-if-ranger-around-advice)

;; (advice-remove 'shackle--display-buffer #'disable-if-ranger-around-advice)

(provide 'pen-ranger)
