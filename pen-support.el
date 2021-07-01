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

(defun e/chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))
(defalias 'chomp 'e/chomp)

(defun get-string-from-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun str (thing)
  "Converts object or string to an unformatted string."

  (if thing
      (if (stringp thing)
          (substring-no-properties thing)
        (progn
          (setq thing (format "%s" thing))
          (set-text-properties 0 (length thing) nil thing)
          thing))
    ""))

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
             (sn "tr '\n' - | slugify" input)
           (sn "slugify" input))))
    (if length
        (substring slug 0 (- length 1))
      slug)))

(cl-defun cl-fz (list &key prompt &key full-frame &key initial-input &key must-match &key select-only-match &key hist-var &key add-props)
          (if (and (not hist-var)
                   (sor prompt))
              (setq hist-var (intern (concat "histvar-fz-" (slugify prompt)))))

          (setq prompt (sor prompt ":"))

          (if (not (re-match-p " $" prompt))
              (setq prompt (concat prompt " ")))

          (if (eq (type-of list) 'symbol)
              (cond
                ((variable-p 'clojure-mode-funcs) (setq list (eval list)))
                ((fboundp 'clojure-mode-funcs) (setq list (funcall list)))))

          (if (stringp list)
              (setq list (string2list list)))

          (if (and select-only-match (eq (length list) 1))
              (car list)
              (progn
                (setq prompt (or prompt ":"))
                (let ((helm-full-frame full-frame)
                      (completion-extra-properties nil))

                  (if add-props
                      (setq completion-extra-properties
                            (append
                             completion-extra-properties
                             add-props)))

                  (if (and (listp (car list)))
                      (setq completion-extra-properties
                            (append
                             '(:annotation-function fz-completion-second-of-tuple-annotation-function)
                             completion-extra-properties)))

                  (completing-read prompt list nil must-match initial-input hist-var)))))

(defun fz (list &optional input b_full-frame prompt must-match select-only-match add-props)
  (cl-fz
   list
   :initial-input input
   :full-frame b_full-frame
   :prompt prompt
   :must-match must-match
   :select-only-match select-only-match
   :add-props add-props))

(defun selected ()
  (or
   (use-region-p)
   (evil-visual-state-p)))

(defun glob (pattern &optional dir)
  (split-string (cl-sn (concat "glob -b " (q pattern) " 2>/dev/null") :stdin nil :dir dir :chomp t) "\n"))

(provide 'pen-support)