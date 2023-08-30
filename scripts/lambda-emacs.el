#!/bin/true

;; Used by:
;; $HOME/.emacs.d/host/pen.el/scripts/lambda-emacs

(load "/root/.emacs.d/elpa/shut-up-20210403.1249/shut-up.el")

(defun pen-sn (shell-cmd &optional stdin dir exit_code_var detach b_no_unminimise output_buffer b_unbuffer chomp b_output-return-code)
  "Runs command in shell and return the result.
This appears to strip ansi codes.
\(sh) does not.
This also exports PEN_PROMPTS_DIR, so lm-complete knows where to find the .prompt files"
  (interactive)

  (let ((output)
        (tf)
        (input_tf))
    (if (not shell-cmd)
        (setq shell-cmd "false"))

    ;; sn must never contain a tramp path
    (if (not dir)
        (let ((cand-dir (get-dir)))
          (if (f-directory-p cand-dir)
              (setq dir cand-dir)
            (setq dir "/"))))

    ;; If the dir is a tramp path, just use root
    (if (string-match "/[^:]+:" dir)
        (setq dir "/"))

    (let ((default-directory dir))
      (if b_unbuffer
          (setq shell-cmd (concat "unbuffer -p " shell-cmd)))

      (if (or (or
               (pen-var-value-maybe 'pen-sh-update)
               (>= (prefix-numeric-value current-global-prefix-arg) 16))
              (or
               (and (variable-p 'pen-sh-update)
                    (eval 'pen-sh-update))
               (>= (prefix-numeric-value current-prefix-arg) 16)))
          (setq shell-cmd (concat "export UPDATE=y; " shell-cmd)))

      (setq shell-cmd (concat ". $HOME/.shellrc; " shell-cmd))

      (setq tf (make-temp-file "elisp_bash"))
      (setq tf_exit_code (make-temp-file "elisp_bash_exit_code"))

      (let ((exps
             (sh-construct-exports
              (-filter 'identity
                       (list (list "DISPLAY" ":0")
                             (list "PATH" (getenv "PATH"))
                             (list "TMUX" "")
                             (list "TMUX_PANE" "")
                             (list "PEN_DAEMON" (sor (daemonp) "default"))
                             (list "PEN_PROMPTS_DIR" (concat pen-prompts-directory "/prompts"))
                             (if (or (pen-var-value-maybe 'pen-sh-update)
                                     (pen-var-value-maybe 'pen-sh-update))
                                 (list "UPDATE" "y"))
                             (if (or (pen-var-value-maybe 'pen-force-engine))
                                 (list "PEN_ENGINE" (pen-var-value-maybe 'pen-force-engine)))
                             (if (or (pen-var-value-maybe 'force-temperature))
                                 (list "PEN_TEMPERATURE" (pen-var-value-maybe 'force-temperature))))))))

        (if (and detach
                 stdin)
            (progn
              (setq input_tf (make-temp-file "elisp_bash_input"))
              (write-to-file stdin input_tf)
              (setq shell-cmd (concat "exec < <(cat " (pen-q input_tf) "); " shell-cmd))))

        (if (not (string-match "[&;]$" shell-cmd))
            (setq shell-cmd (concat shell-cmd ";")))

        (if (and detach
                 stdin)
            (setq final_cmd (concat final_cmd " rm -f " (pen-q input_tf) ";")))

        ;; I need a log level here. This will be too verbose
        (setq final_cmd (pen-log-verbose
                         (concat exps "; ( cd " (pen-q dir) "; " shell-cmd " echo -n $? > " tf_exit_code " ) > " tf))))

      (if detach
          (if stdin
              (setq final_cmd (concat "trap '' HUP; bash -c " (pen-q final_cmd) " &"))
            (setq final_cmd (concat "trap '' HUP; unbuffer bash -c " (pen-q final_cmd) " &"))))

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
          (setq output (slurp-file tf))
          (if chomp
              (setq output (chomp output)))
          (progn
            (defset b_exit_code (slurp-file tf_exit_code)))

          (if b_output-return-code
              (setq output (str b_exit_code)))
          (ignore-errors
            (progn (f-delete tf)
                   (f-delete tf_exit_code)))
          output)))))

(defun pen-snc (shell-cmd &optional stdin dir)
  "sn chomp"
  (chomp (pen-sn shell-cmd stdin dir)))

(defun cat-to-file (stdin file_path)
  ;; The ignore-errors is needed for babel for some reason
  (ignore-errors (with-temp-buffer
                   (insert stdin)
                   (delete-file file_path)
                   (write-file file_path))))

(defalias 'write-string-to-file 'cat-to-file)
(defalias 'write-to-file 'cat-to-file)

(defun chomp (str)
  "Chomp (remove tailing newline from) STR."
  (replace-regexp-in-string "\n\\'" "" str))

(defun pen-q (&rest strings)
  (let ((print-escape-newlines t))
    (mapconcat 'identity (mapcar 'prin1-to-string-safe strings) " ")))

(defalias 'e/escape-string 'pen-q)
(defalias 'e/q 'pen-q)

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
(defalias 'sor 'string-first-nonnil-nonempty-string)

(defun pen-tf (template &optional input ext)
  "Create a temporary file."
  (setq ext (or ext "txt"))
  (let ((fp (pen-snc (concat "mktemp -p /tmp " (pen-q (concat "XXXX" (slugify template) "." ext))))))
    (if (and (sor fp)
             (sor input))
        (shut-up (write-to-file input fp)))
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

(defun e/cat (&optional path input)
  "cat out a file, or write to one"
  (cond
   ((and (test-f path) input) (write-to-file input path))
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

(defun new-buffer-from-string (&optional contents bufname mode nodisplay)
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
(defalias 'nbfs 'new-buffer-from-string)

(tool-bar-mode -1)
(menu-bar-mode -1)
(with-current-buffer (nbfs (e/cat "/root/.emacs.d/host/pen.el/scripts/lambda-emacs"))
  (local-set-key "q" 'save-buffers-kill-terminal)
  (read-only-mode 1))
(message "")
