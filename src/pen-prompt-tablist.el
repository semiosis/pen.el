(require 'tabulated-list)
(require 'pcsv)
(require 'tablist)

(defvar pen-prompts-tablist-data-command "oci prompts-details -csv")

(defvar pen-prompts-tablist-meta '("prompts" t "30 30 20 10 15 15 15 10"))

(defmacro defcmdmode (cmd &optional cmdtype)
  (setq cmd (str cmd))
  (setq cmdtype (or cmdtype "term"))
  (let* ((cmdslug (slugify (str cmd)))
         (modestr (concat cmdslug "-" cmdtype "-mode"))
         (modesym (intern modestr))
         (mapsym (intern (concat modestr "-map"))))
    `(progn
       (defvar ,mapsym (make-sparse-keymap)
         ,(concat "Keymap for `" modestr "'."))
       (defvar-local ,modesym nil)

       (define-minor-mode ,modesym
         ,(concat "A minor mode for the '" cmd "' " cmdtype " command.")
         :global nil
         :init-value nil
         :lighter ,(s-upcase cmdslug)
         :keymap ,mapsym)
       (provide ',modesym))))

(defcmdmode "prompts" "tablist")

(defun tablist-buffer-from-csv-string (csvstring &optional has-header col-sizes)
  "This creates a new tabulated list buffer from a CSV string"
  (let* ((b (nbfs csvstring "tablist"))
         (parsed (pcsv-parse-buffer b))
         (header (if has-header
                     (first parsed)
                   (mapcar (λ (s) "") (first parsed))))
         (data (if has-header
                   (-drop 1 parsed)
                 parsed)))

    (switch-to-buffer b)
    (with-current-buffer b

      (setq-local tabulated-list-format
                  (si "tabulated-list-format format"
                      (list2vec
                       (let* ((sizes
                               (or col-sizes
                                   (mapcar (λ (e)
                                             (max my-tablist-min-column-width (min 30 (length e))))
                                           header)))
                              (trues (mapcar (λ (e) t)
                                             header)))
                         (-zip header sizes trues))
                       )))
      (setq-local tabulated-list-sort-key (list (first header)))

      (setq-local tabulated-list-entries (-map (λ (l) (list (first l) (list2vec l))) data))

      (tabulated-list-mode)

      (tabulated-list-init-header)

      (tabulated-list-print)
      (tablist-enlarge-column)
      (tablist-shrink-column)
      (revert-buffer)
      (tablist-forward-column 1)
      (tabulated-list-revert))
    b))

(defun create-tablist (cmd-or-csv-path &optional modename has-header col-sizes-string wd)
  "Try to create a tablist from a command or a csv path"
  (interactive (list (read-string-hist "create-tablist: CMD or CSV path: ")))

  (setq has-header
        (if (sor has-header)
            t
          nil))

  (let* ((path (if (and
                    (f-file-p cmd-or-csv-path)
                    (not (f-executable-p cmd-or-csv-path)))
                   cmd-or-csv-path))
         (command (if (not path)
                  cmd-or-csv-path))
         (col-sizes
          (if (sor col-sizes-string)
              (try (mapcar 'string-to-number (uncmd col-sizes-string))))))

    (let ((b (cond ((sor path) (tablist-buffer-from-csv-string (cat path) has-header col-sizes))
                   ((sor command) (tablist-buffer-from-csv-string (pen-sn command) has-header col-sizes)))))
      (if b
          (with-current-buffer
              b
            (if (sor wd) (cd wd))
            (let ((modefun (intern (concat (slugify (or modename cmd-or-csv-path)) "-tablist-mode"))))
              (if (fboundp modefun)
                  (funcall modefun)))
            b)
        (error "tablist not created")
        nil))))

(defun pen-prompts-tablist-start ()
  (interactive)
  (let* ((pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 16)))
    (apply 'create-tablist (cons pen-prompts-tablist-data-command pen-prompts-tablist-meta))))

(provide 'pen-tablist)