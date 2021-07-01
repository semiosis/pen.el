(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defun message-no-echo (format-string &rest args)
  (let ((inhibit-read-only t))
    (with-current-buffer (messages-buffer)
      (goto-char (point-max))
      (when (not (bolp))
        (insert "\n"))
      (insert (apply 'format format-string args))
      (when (not (bolp))
        (insert "\n")))))

(defun string-empty-or-nil-p (s)
  (or (not s)
      (string-empty-p s)))

(defun string-not-empty-nor-nil-p (s)
  (not (string-empty-or-nil-p s)))

(defun string-first-nonnil-nonempty-string (&rest ss)
  "Get the first non-nil string."
  (let ((result))
    (catch 'bbb
      (dolist (p ss)
        (if (string-not-empty-nor-nil-p p)
            (progn
              (setq result p)
              (throw 'bbb result)))))
    result))

(defun cwd ()
  "Gets the current working directory"
  (interactive)
  (substring (shut-up-c (pwd)) 10))

(defun get-dir ()
  "Gets the directory of the current buffer's file. But this could be different from emacs' working directory.
Takes into account the current file name."
  (shut-up-c
   (let ((filedir (if buffer-file-name
                      (file-name-directory buffer-file-name)
                    (file-name-directory (cwd)))))
     (if (s-blank? filedir)
         (cwd)
       filedir))))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun e/escape-string (&rest strings)
  (let ((print-escape-newlines t))
    (s-join " " (mapcar 'prin1-to-string strings))))
(defalias 'e/q 'e/escape-string)
(defalias 'q 'e/escape-string)

(defun sh-notty (cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not."
  (interactive)

  (if (not cmd)
      (setq cmd "false"))

  (if (not dir)
      (setq dir (get-dir)))

  (let ((default-directory dir))
    (if (not b_no_unminimise)
        (setq cmd (umn cmd)))

    (if b_unbuffer
        (setq cmd (concat "unbuffer -p " cmd)))

    (if (or
         (and (variable-p 'sh-update)
              (eval 'sh-update))
         (>= (prefix-numeric-value current-global-prefix-arg) 16))
        (setq cmd (concat "upd " cmd)))

    (setq tf (make-temp-file "elisp_bash"))
    (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

    (let ((exps
           (sh-construct-exports
            (-filter 'identity
                     (list (list "PATH" (concat "$SCRIPTS:" (getenv "PATH")))
                           (if (and (variable-p 'sh-update) (eval 'sh-update))
                               (list "UPDATE" "y")))))))
      (setq final_cmd (concat exps "; ( cd " (e/q dir) "; " cmd "; echo -n $? > " tf_exit_code " ) > " tf)))

    (message-no-echo "%s" (concat "sh-notty: " (mnm final_cmd)))

    (if detach
        (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (e/q final_cmd) " &")))

    (shut-up-c
     (if (not stdin)
         (progn
           (shell-command final_cmd output_buffer))
       (with-temp-buffer
         (insert stdin)
         (shell-command-on-region (point-min) (point-max) final_cmd output_buffer))))
    (setq output (get-string-from-file tf))
    (if chomp
        (setq output (chomp output)))
    (progn
      (defset b_exit_code (get-string-from-file tf_exit_code)))

    (if b_output-return-code
        (setq output (str b_exit_code)))
    output))

(defun slugify (input &optional joinlines length)
  "Slugify input"
  (interactive)
  (let ((slug
         (if joinlines
             (sh-notty "tr '\n' - | slugify" input)
           (sh-notty "slugify" input))))
    (if length
        (substring slug 0 (- length 1))
      slug)))

(defun fz (list &optional input b_full-frame prompt must-match select-only-match add-props)
  (cl-fz
   list
   :initial-input input
   :full-frame b_full-frame
   :prompt prompt
   :must-match must-match
   :select-only-match select-only-match
   :add-props add-props))

(provide 'pen-support)