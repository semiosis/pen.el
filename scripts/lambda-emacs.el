;; Used by:
;; $HOME/.emacs.d/host/pen.el/scripts/lambda-emacs

(defmacro df (name &rest body)
  "Named interactive lambda with no arguments"
  `(defun ,name ()
     (interactive)
     ,@body))

(load "/root/.emacs.d/host/pen.el/src/pen-translation-map.el")
(define-key global-map (kbd "C-h") (kbd "DEL"))

(load "/root/.emacs.d/elpa/shut-up-20210403.1249/shut-up.el")

(defmacro defset (symbol value &optional documentation)
  "Instead of doing a defvar and a setq, do this. [[http://ergoemacs.org/emacs/elisp_defvar_problem.html][ergoemacs.org/emacs/elisp_defvar_problem.html]]"

  `(progn (defvar ,symbol ,documentation)
          (setq ,symbol ,value)))

(defun sh-construct-exports (varval-tuples)
  (concat
   "export "
   (sh-construct-envs varval-tuples)))

(defun -filter (pred list)
  "Return a new list of the items in LIST for which PRED returns non-nil.
"
  (let
      (result)
    (let
        ((list list)
         (i 0)
         it it-index)
      (ignore it it-index)
      (while list
        (setq it
              (car-safe
               (prog1 list
                 (setq list
                       (cdr list))))
              it-index i i
              (1+ i))
        (if
            (funcall pred it)
            (progn
              (setq result
                    (cons it result))))))
    (nreverse result)))

(defun s-join (separator strings)
  "Join all the strings in STRINGS with SEPARATOR in between."
  (declare (pure t) (side-effect-free t))
  (mapconcat 'identity strings separator))

(defun sh-construct-envs (varval-tuples)
  (s-join
   " "
   (-filter
    'identity
    (cl-loop for tp in varval-tuples
             collect
             (let ((lhs (car tp))
                   (rhs (cadr tp)))
               (if tp
                   (concat
                    lhs
                    "="
                    (if rhs
                        (if (booleanp rhs)
                            "y"
                          (q rhs))
                      ""))))))))

(defun var-value-maybe (sym)
  "This function gets the value of the symbol"
  (cond
   ((symbolp sym) (if (variable-p sym)
                      (eval sym)))
   ((numberp sym) sym)
   ((stringp sym) sym)
   (t sym)))

(defmacro shut-up-c (&rest body)
  "This works for c functions where shut-up does not."
  `(progn (let* ((inhibit-message t))
            ,@body)))

(defun cwd ()
  "Gets the current working directory"
  (interactive)
  (let ((c (shut-up-c (pwd))))
    (if c
        (expand-file-name (substring c 10))
      default-directory)))

(defun s-blank? (s)
  "Is S nil or the empty string?"
  (declare (pure t) (side-effect-free t))
  (or (null s) (string= "" s)))

(defun get-dir (&optional dont-clean-tramp)
  "Gets the directory of the current buffer's file. But this could be different from emacs' working directory.
Takes into account the current file name."
  (shut-up-c
   (let* ((filedir (if buffer-file-name
                       (file-name-directory buffer-file-name)
                     (file-name-directory (cwd))))
          (dir
           (if (s-blank? filedir)
               (cwd)
             filedir)))
     dir)))

(defun file-delete (path &optional force)
  "Delete PATH, which can be file or directory."
  (if (or (file-regular-p path) (not (not (file-symlink-p path))))
      (delete-file path)
    (delete-directory path force)))

(defun variable-p (s)
  (and (not (eq s nil))
       (boundp s)))

(defun sn (shell-cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not.
This also exports PEN_PROMPTS_DIR, so lm-complete knows where to find the .prompt files"
  (interactive)

  (let ((output)
        (output_tf)
        (input_tf))
    (if (not shell-cmd)
        (setq shell-cmd "false"))

    ;; sn must never contain a tramp path
    (if (not dir)
        (let ((cand-dir (get-dir)))
          (if (file-directory-p cand-dir)
              (setq dir cand-dir)
            (setq dir "/"))))

    ;; If the dir is a tramp path, just use root
    (if (string-match "/[^:]+:" dir)
        (setq dir "/"))

    (let ((default-directory dir))
      (if b_unbuffer
          (setq shell-cmd (concat "unbuffer -p " shell-cmd)))

      (if (or (or
               (and (variable-p 'sh-update)
                    (eval 'sh-update))
               (>= (prefix-numeric-value current-prefix-arg) 16)))
          (setq shell-cmd (concat "export UPDATE=y; " shell-cmd)))

      (setq shell-cmd (concat ". $HOME/.shellrc; " shell-cmd))

      (setq output_tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (let ((exps
             (sh-construct-exports
              (-filter 'identity
                       (list (list "DISPLAY" ":0")
                             (list "PATH" (getenv "PATH"))
                             (list "TMUX" "")
                             (list "TMUX_PANE" ""))))))

        (if (and detach
                 stdin)
            (progn
              (setq input_tf (make-temp-file "elisp_bash_input"))
              (cat input_tf stdin)
              (setq shell-cmd (concat "exec < <(cat " (q input_tf) "); " shell-cmd))))

        (if (not (string-match "[&;]$" shell-cmd))
            (setq shell-cmd (concat shell-cmd ";")))

        (if (and detach
                 stdin)
            (setq final_cmd (concat final_cmd " rm -f " (q input_tf) ";")))

        ;; I need a log level here. This will be too verbose
        (setq final_cmd (concat exps "; ( cd " (q dir) "; " shell-cmd " echo -n $? > " tf_exit_code " ) > " output_tf)))

      (if detach
          (if stdin
              (setq final_cmd (concat "trap '' HUP; bash -c " (q final_cmd) " &"))
            (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (q final_cmd) " &"))))

      (shut-up-c
       (if (or
            (not stdin)
            detach)
           (shell-command final_cmd output_buffer "*pen-sn-stderr*")
         (with-temp-buffer
           (insert stdin)
           (shell-command-on-region (point-min) (point-max) final_cmd output_buffer nil "*pen-sn-stderr*"))))

      (if detach
          t
        (progn
          (setq output (cat output_tf))
          (if chomp
              (setq output (chomp output)))
          (progn
            (defset b_exit_code (cat tf_exit_code)))

          (if b_output-return-code
              (setq output (str b_exit_code)))
          (ignore-errors
            (progn (file-delete output_tf)
                   (file-delete tf_exit_code)))
          output)))))

(defun snc (shell-cmd &optional stdin dir)
  "sn chomp"
  (chomp (sn shell-cmd stdin dir)))

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun prin1-to-string-safe (s)
  (if s
      (prin1-to-string s)
    "\"\""))

(defun q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string-safe strings) " ")))

(defun string-empty-or-nil-p (s)
  (or (not s)
      (string-empty-p s)))

(defun string-not-empty-nor-nil-p (s)
  (not (string-empty-or-nil-p s)))

(defun sor (&rest ss)
  "Get the first non-nil string."
  (let ((result))
    (catch 'bbb
      (dolist (p ss)
        (if (string-not-empty-nor-nil-p p)
            (progn
              (setq result p)
              (throw 'bbb result)))))
    result))

(defun pen-tf (template &optional input ext)
  "Create a temporary file."
  (setq ext (or ext "txt"))
  (let ((fp (snc (concat "mktemp -p /tmp " (q (concat "XXXX" (slugify template) "." ext))))))
    (if (and (sor fp)
             (sor input))
        (shut-up (cat fp input)))
    fp))

(defalias 'test-z 'string-empty-p)
(defalias 'test-f 'file-exists-p)

(defun test-n (s)
  (not (string-empty-p s)))

(setq mode-line-format nil)
(setq-default mode-line-format nil) 
(define-key global-map (kbd "q") #'save-buffers-kill-terminal)

(define-key key-translation-map (kbd "C-M-k") (kbd "<up>"))
(define-key key-translation-map (kbd "C-M-j") (kbd "<down>"))
(define-key key-translation-map (kbd "C-M-h") (kbd "<left>"))
(define-key key-translation-map (kbd "C-M-l") (kbd "<right>"))

(defun cat (&optional path input)
  "cat out a file, or write to one"
  (cond
   ((and (test-f path) input)
    (ignore-errors (with-temp-buffer
                   (insert input)
                   (delete-file path)
                   (write-file path))))
   ((test-f path) (with-temp-buffer
                    (insert-file-contents path)
                    (buffer-string)))
   (t (error "Bad path"))))

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

(defvar new-buffer-hooks '())

(defun nbfs (&optional contents bufname mode nodisplay)
  "Create a new untitled buffer from a string."
  (interactive)
  (if (not bufname)
      (setq bufname "*untitled*"))
  (let ((buffer (generate-new-buffer bufname)))
    (set-buffer-major-mode buffer)
    (if (not nodisplay)
        (display-buffer buffer '(display-buffer-same-window . nil)))
    (with-current-buffer buffer
      (if contents
          (if (stringp contents)
              (insert contents)
            (insert (str contents))))
      (beginning-of-buffer)
      (if mode (funcall mode))
      ;; This may not be available
      (ignore-errors (pen-add-ink-change-hook)))
    buffer))

(tool-bar-mode -1)
(menu-bar-mode -1)
