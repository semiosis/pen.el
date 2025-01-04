(require 'tabulated-list)
(require 'pcsv)
(require 'tablist)

;; (defset pen-supervisor-tablist-data-command "oci supervisor-details -tsv")
(defset pen-supervisor-tablist-data-command "oci supervisor-details -tsv | tsv2csv")

(defset pen-supervisor-tablist-meta '("supervisor" t "20 70"))

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

(defun supervisor-tablist-get-fp ()
  (sps "supervisor-details | fpvd"))

(defun supervisor-tablist-fpvd ()
  (interactive)
  (sps "supervisor-details | fpvd"))

(defun supervisor-tablist-o ()
  (interactive)
  ;; (e (supervisor-tablist-get-fp))
  )

(defcmdmode "supervisor" "tablist")
(define-key supervisor-tablist-mode-map (kbd "p") 'supervisor-tablist-fpvd)
(define-key supervisor-tablist-mode-map (kbd "RET") 'supervisor-tablist-o)



(defun create-tablist (cmd-or-csv-path &optional modename has-header col-sizes-string wd)
  "Try to create a tablist from a command or a csv path"
  (interactive (list (read-string-hist "create-tablist: CMD or CSV path: ")))

  (setq has-header
        (if (sor has-header)
            t
          nil))

  (let* ((path (if (and
                    (f-file-p cmd-or-csv-path)
                    ;; Might be a shell command
                    ;; (not (f-executable-p cmd-or-csv-path))
                    )
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

(defun pen-supervisor-tablist-start ()
  (interactive)
  (let* ((pen-sh-update (>= (prefix-numeric-value current-global-prefix-arg) 16)))
    (apply 'create-tablist (cons pen-supervisor-tablist-data-command pen-supervisor-tablist-meta))))

(provide 'pen-supervisor-tablist)
