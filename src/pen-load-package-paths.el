(require 'cl-macs)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun string2list (s)
  "Convert a newline delimited string to list."
  (split-string s "\n"))

(defun list2string (list)
  "Convert a list to a newline delimited string."
  (mapconcat 'str list "\n"))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string strings) " ")))

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun slurp-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun pen-sn-basic (cmd &optional stdin dir)
  (interactive)

  (let ((output))
    (if (not cmd)
        (setq cmd "false"))

    (if (not dir)
        (setq dir default-directory))

    (let ((default-directory dir))
      (if (or
           (and (variable-p 'sh-update)
                (eval 'sh-update))
           (>= (prefix-numeric-value current-prefix-arg) 16))
          (setq cmd (concat "export UPDATE=y; " cmd)))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (setq final_cmd (concat "( cd " (pen-q dir) "; " cmd " ) > " tf))

      (shut-up-c
       (with-temp-buffer
         (insert (or stdin ""))
         (shell-command-on-region (point-min) (point-max) final_cmd)))
      (setq output (slurp-file tf))
      (ignore-errors
        (progn (f-delete tf)
               (f-delete tf_exit_code)))
      output)))

(defun list-directories-recursively (dir)
  (string2list
   (chomp
    (pen-sn-basic
     (concat "find -P " (pen-q dir) " -maxdepth 2 \\( -name 'snippets' -o -name '*-snippets*' \\) -prune -o -type d")
     nil
     "/"))))

(defun f-realpath (path &optional dir)
  (if path
      (chomp (pen-sn-basic (concat "realpath " (pen-q path) " 2>/dev/null") nil dir))))

(defun pen-daemon-name ()
  (let ((d (daemonp)))
    (if d
        (if (stringp d)
            (f-filename (daemonp))
          ;; Sometimes it's a bool
          "DEFAULT")
      "")))

(defun pen-set-package-paths ()
  (interactive)
  (if (string-match "^pen-emacsd-" (pen-daemon-name))
      (setq load-path (cl-union load-path (list-directories-recursively (f-realpath (f-full "/root/.emacs.d/elpa-light/")))))
    (setq load-path (cl-union load-path (list-directories-recursively (f-realpath (f-full "/root/.emacs.d/elpa-full/"))))))

  (if (f-directory-p (f-full "/root/.emacs.d/manual-packages/"))
      (setq load-path (cl-union load-path (list-directories-recursively (f-realpath (f-full "/root/.emacs.d/manual-packages/")))))))

(pen-set-package-paths)

(provide 'pen-load-package-paths)