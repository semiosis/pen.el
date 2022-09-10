(require 'counsel)
(require 'helm)
(require 'grep)
(require 's)
(require 'wgrep)

(uk grep-mode-map "g")

(cl-defun pen-counsel-ag (&optional initsearch extra-args prompt &key histvar &key basecmd)
  (interactive)

  (if (not basecmd)
      (setq basecmd "pen-counsel-ag-cmd %s"))

  (setq counsel-ag-base-command basecmd)

  (let ((dir (if (equalp current-prefix-arg '(4))
                 (projectile-acquire-root)
               (pen-pwd))))

    (if (region-active-p)
        (setq initsearch (pen-selected-text)))

    (if (or (region-active-p)
            iedit-mode
            (>= (prefix-numeric-value current-prefix-arg) 16))
        (let ((current-prefix-arg nil))
          (deactivate-mark)
          (eval `(counsel-ag (or
                              initsearch
                              (default-search-string))
                             dir extra-args prompt
                             :histvar ,histvar)))
      ;; initsearch is usually nil
      (eval `(counsel-ag initsearch dir extra-args prompt :histvar ,histvar)))))

(defun pen-counsel-ag-generic (pen-cmd &optional initsearch extra-args prompt)
  (interactive (list (read-string-hist "base grep cmd: ")))

  (let ((histvar (intern (slugify (concat "histvar-" cm))))
        (basecmd (if (not (string-match "%s" cm))
                     (concat cm " %s"))))
    (eval `(defvar ,histvar '()))
    (pen-counsel-ag initsearch extra-args prompt :histvar histvar :basecmd basecmd)))

(defun pen-counsel-ag-generic-e (pen-cmd &optional initsearch extra-args prompt)
  (interactive (list (read-string-hist "base grep cmd: ")))
  (pen-counsel-ag-generic cm initsearch extra-args prompt))

(defun pen-counsel-ag-thing-at-point (&optional initsearch &rest body)
  (interactive)
  (let ((thing (pen-thing-at-point))
        (p (point))
        (m (mark))
        (s mark-active))
    (deactivate-mark)
    (eval
     `(try
       (pen-counsel-ag (or ,initsearch
                          (eatify ,thing)))
       (progn
         (set-mark ,m)
         (goto-char ,p)
         ,(if s
              '(activate-mark)
            '(deactivate-mark))
         (error "lsp-ui-peek-find-references failed"))))))

(defun grep-mode-hook-run ()
  (ignore-errors
    ;; This saves the keymap so it can be restored
    (ivy-wgrep-change-to-wgrep-mode)
    (wgrep-setup)

    (define-key compilation-button-map (kbd "C-m") 'compile-goto-error)
    (define-key compilation-button-map (kbd "RET") 'compile-goto-error)
    (define-key grep-mode-map (kbd "C-m") 'compile-goto-error)
    (visual-line-mode -1)))

(defun ag-dir (&optional dir)
  (interactive (list (read-string-hist "ag dir:")))
  (with-current-buffer
    (dired dir)
    (call-interactively 'pen-counsel-ag)))
(add-hook 'grep-mode-hook 'grep-mode-hook-run t)

(defun compilation-find-file (marker filename directory &rest formats)
  "Find a buffer for file FILENAME.
If FILENAME is not found at all, ask the user where to find it.
Pop up the buffer containing MARKER and scroll to MARKER if we ask
the user where to find the file.
Search the directories in `compilation-search-path'.
A nil in `compilation-search-path' means to try the
\"current\" directory, which is passed in DIRECTORY.
If DIRECTORY is relative, it is combined with `default-directory'.
If DIRECTORY is nil, that means use `default-directory'.
FORMATS, if given, is a list of formats to reformat FILENAME when
looking for it: for each element FMT in FORMATS, this function
attempts to find a file whose name is produced by (format FMT FILENAME)."
  (setq filename (pen-umn filename))
  (or formats (setq formats '("%s")))
  (let ((dirs compilation-search-path)
        (spec-dir (if directory
                      (expand-file-name directory)
                    default-directory))
        buffer thisdir fmts name)
    (if (file-name-absolute-p filename)
        ;; The file name is absolute.  Use its explicit directory as
        ;; the first in the search path, and strip it from FILENAME.
        (setq filename (abbreviate-file-name (expand-file-name filename))
              dirs (cons (file-name-directory filename) dirs)
              filename (file-name-nondirectory filename)))
    ;; Now search the path.
    (while (and dirs (null buffer))
      (setq thisdir (or (car dirs) spec-dir)
            fmts formats)
      ;; For each directory, try each format string.
      (while (and fmts (null buffer))
        (setq name (expand-file-name (format (car fmts) filename) thisdir)
              buffer (and (file-exists-p name)
                          (find-file-noselect name))
              fmts (cdr fmts)))
      (setq dirs (cdr dirs)))
    (while (null buffer)        ;Repeat until the user selects an existing file.
      ;; The file doesn't exist.  Ask the user where to find it.
      (save-excursion                   ;This save-excursion is probably not right.
        (let ((w (let ((pop-up-windows t))
                   (display-buffer (marker-buffer marker)
                                   '(nil (allow-no-window . t))))))
          (with-current-buffer (marker-buffer marker)
            (goto-char marker)
            (and w (compilation-set-window w marker)))
          (let* ((name (read-file-name
                        (format "Find this %s in (default %s): "
                                compilation-error filename)
                        spec-dir filename t nil))
                 (origname name))
            (cond
             ((not (file-exists-p name))
              (message "Cannot find file `%s'" name)
              (ding) (sit-for 2))
             ((and (file-directory-p name)
                   (not (file-exists-p
                         (setq name (expand-file-name filename name)))))
              (message "No `%s' in directory %s" filename origname)
              (ding) (sit-for 2))
             (t
              (setq buffer (find-file-noselect name))))))))
    ;; Make intangible overlays tangible.
    ;; This is weird: it's not even clear which is the current buffer,
    ;; so the code below can't be expected to DTRT here.  -- Stef
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (overlay-get ov 'intangible)
        (overlay-put ov 'intangible nil)))
    buffer))

(defun grep-get-paths ()
  (if (derived-mode-p 'grep-mode)
      (pen-sn "grep-output-get-paths" (pen-buffer-string-or-selection))))

(defun grep-ead-on-results (paths query)
  (interactive (list
                (grep-get-paths)
                (read-string "ead on results:" (pen-selection))))
  (pen-sps (concat "pen-umn | uniqnosort | pen-ead " query) "" paths))

(defun grep-eead-on-results (paths query)
  (interactive (list
                (grep-get-paths)
                (read-string "eead on results:" (pen-selection))))
  (eead-thing-at-point query paths))

(defun grep-output-get-paths (paths)
  (interactive (list (pen-buffer-string-or-selection)))
  (pen-sps "v" "" (pen-sn "grep-output-get-paths" paths)))

(defun counsel--format-ag-command (extra-args needle)
  "Construct a complete `counsel-ag-command' as a string.
EXTRA-ARGS is a string of the additional arguments.
NEEDLE is the search string."
  (counsel--format counsel-ag-command
                   (if (listp counsel-ag-command)
                       (if (string-match " \\(--\\) " extra-args)
                           (counsel--format
                            (split-string (replace-match "%s" t t extra-args 1))
                            needle)
                         (nconc (split-string extra-args) needle))
                     (if (string-match " \\(--\\) " extra-args)
                         (replace-match needle t t extra-args 1)
                       (concat extra-args " " needle)))))

(defun vc-get-top-level ()
  (s-replace-regexp "/$" "" (projectile-project-root)))

(defun sps-ead-thing-at-point ()
  (interactive)
  ;; TODO complete pen-ead
  (pen-sph (concat "pen-ead " (pen-q (pen-eatify (str (pen-thing-at-point)))))))

(defun pen-grep-eead-on-results (paths query)
  (interactive (list
                (grep-get-paths)
                (read-string "pen-ead:" (pen-thing-at-point))))
  (pen-eead-thing-at-point query paths))

(defun pen-wgrep-thing-at-point (s &optional dir)
  (interactive (list (pen-thing-at-point)))  
  (if (major-mode-p 'grep-mode)
      (call-interactively 'pen-grep-eead-on-results)
    (if dir
        (wgrep (pen-eatify (str s)) dir)
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          ;; use top dir if prefix is specified
          (let ((current-prefix-arg nil))
            (wgrep (pen-eatify (str s)) (vc-get-top-level)))
        ;; use current directory by default
        (wgrep (pen-eatify (str s)) (pen-pwd))))))

(defun pen-eatify (pat)
  (if (re-match-p "^[a-zA-Z_]" pat)
      (setq pat (concat "\\b" pat)))
  (if (re-match-p "[a-zA-Z_]$" pat)
      (setq pat (concat pat "\\b")))
  pat)

;; This is so nice and fast! I should definitely stay within emacs!

(defun pen-eead-thing-at-point (&optional thing paths-string dir)
  (interactive (list (str (pen-thing-at-point))
                     nil
                     (get-top-level)))

  ;; Sometimes the function is not called interactively
  (setq thing (or thing (str (pen-thing-at-point))))
  (setq dir (or dir (get-top-level)))

  (let* ((cm (concat "pen-ead " (pen-q (pen-eatify thing))))
         (cmdnoeat (if (sor  paths-string)
                       (concat "pen-umn | uniqnosort | pen-ead " (pen-q thing))
                     (concat "pen-ead " (pen-q thing))))
         (slug (slugify cmdnoeat))
         (bufname (concat "*grep:" slug "*"))
         (results (string-or (pen-sn cm paths-string)
                             (pen-sn cmdnoeat))))

    (with-current-buffer (new-buffer-from-string results
                                                 bufname)
      (cd dir)
      (grep-mode)
      (ivy-wgrep-change-to-wgrep-mode)
      (define-key compilation-button-map (kbd "C-m") 'compile-goto-error)
      (define-key compilation-button-map (kbd "RET") 'compile-goto-error)
      (visual-line-mode -1))))

(defun pen-grep-for-thing-select ()
  (interactive)
  (let ((action
         (pen-qa
          -h "here"
          -r "repo")))
    (cond
     ((string-equal "here" action)
      (call-interactively 'pen-wgrep-thing-at-point))
     ((string-equal "repo" action)
      (pen-wgrep-thing-at-point (pen-thing-at-point) (vc-get-top-level)))
     (t
      (call-interactively 'pen-wgrep-thing-at-point)))))

(defun pen-sh-wgrep (pattern &optional wd)
  (interactive (list (read-string-hist "ead pattern: ")
                     (read-directory-name "ead dir: ")))
  (pen-nw (concat "set -x; cd " (pen-q wd) "; pen-ead " (pen-q (concat "\\b" pattern "\\b")) " || pak")))

(defun pen-wgrep (pattern &optional wd path-re)
  (interactive (list (read-string-hist "ead pattern: ")
                     (read-directory-name "ead dir: ")))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-sh-wgrep pattern wd)
    (progn
      (if (not wd)
          (setq wd (pen-pwd)))
      (setq wd (pen-umn wd))
      (with-current-buffer
          ;; How can I use pen-mnm but only on the file paths? -- I want to be able to filter on a column only
          (let ((globstr (if (sor path-re)
                             (concat "-p " (pen-q path-re) " ")
                           "")))
            (new-buffer-from-string
             (ignore-errors (pen-sn (concat "pen-ead -f " globstr (pen-q pattern) " | pen-mnm | cat") nil wd))
             "*wgrep*"))
        (grep-mode)))))
(defalias 'ead 'pen-wgrep)

(if (inside-docker-p)
    (defalias 'wgrep 'pen-wgrep))

(define-key global-map (kbd "H-H") 'pen-counsel-ag-generic)
(define-key grep-mode-map (kbd "C-c C-p") #'ivy-wgrep-change-to-wgrep-mode)
(define-key global-map (kbd "M-?") #'pen-counsel-ag)
(define-key global-map (kbd "M-\"") #'pen-helm-fzf)
(define-key grep-mode-map (kbd "h") nil)
(define-key global-map (kbd "RET") 'newline)
(define-key grep-mode-map (kbd "RET") 'compile-goto-error)
(define-key grep-mode-map (kbd "C-x C-q") #'ivy-wgrep-change-to-wgrep-mode)
(define-key grep-mode-map (kbd "M-3") 'grep-eead-on-results)
(define-key global-map (kbd "M-3") #'pen-grep-for-thing-select)

(provide 'pen-grep)
