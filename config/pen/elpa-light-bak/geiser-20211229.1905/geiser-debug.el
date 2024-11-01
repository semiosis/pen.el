;;; geiser-debug.el -- displaying debug and eval info  -*- lexical-binding: t; -*-

;; Copyright (C) 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2020, 2021 Jose Antonio Ortega Ruiz

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.

;; Start date: Mon Feb 23, 2009 22:34


;;; Code:

(eval-when-compile (require 'cl-macs))

(require 'geiser-edit)
(require 'geiser-autodoc)
(require 'geiser-impl)
(require 'geiser-eval)
(require 'geiser-menu)
(require 'geiser-popup)
(require 'geiser-base)
(require 'geiser-image)

(require 'transient)
(require 'ansi-color)


;;; Customization:

(defgroup geiser-debug nil
  "Debugging and error display options."
  :group 'geiser)

(geiser-custom--defcustom geiser-debug-always-display-sexp-after-p nil
  "Whether to always display the sexp whose evaluation caused an
error after the error message in the debug pop-up. If nil,
expressions shorter than `geiser-debug-long-sexp-lines` lines are
shown before the error message."
  :type 'boolean)

(geiser-custom--defcustom geiser-debug-long-sexp-lines 6
  "Length of an expression in order to be relegated to the bottom
of the debug pop-up (after the error message). If
`geiser-debug-always-display-sexp-after-p` is t, this variable
has no effect."
  :type 'int)

(geiser-custom--defcustom geiser-debug-jump-to-debug-p t
  "When set to t (the default), jump to the debug pop-up buffer
in case of evaluation errors.

See also `geiser-debug-show-debug-p`. "
  :type 'boolean)

(geiser-custom--defcustom geiser-debug-auto-next-error-p nil
  "When set, automatically invoke `next-error' on of evaluation errors.

This will make point jump to the location of an error if the output
of the evaluation contains any."
  :type 'boolean)

(geiser-custom--defcustom geiser-debug-show-debug-p t
  "When set to t (the default), show the debug pop-up buffer in
case of evaluation errors.

This option takes effect even if `geiser-debug-jump-to-debug-p`
is set."
  :type 'boolean)

(geiser-custom--defcustom geiser-debug-auto-display-images-p t
  "Whether to automatically invoke the external viewer to display
images when they're evaluated.

See also `geiser-repl-auto-display-images-p'."
  :type 'boolean)

(geiser-custom--defcustom geiser-debug-treat-ansi-colors nil
  "Colorize ANSI escape sequences produced by the scheme process.

Some schemes are able to colorize their evaluation or error
results using ANSI color sequences (e.g. when using the the
colorized module in Guile).

If set to `nil', no special treatment is applied to output.  The
symbol colors indicates colorizing the display of the Geiser dbg
buffer using any color escape, and the symbol remove to remove
all ANSI sequences."
  :type '(choice (const :tag "No special treatment" nil)
                 (const :tag "Use font lock for colors" colors)
                 (const :tag "Remove all ANSI codes" remove)))


;;; Debug buffer mode:

(defvar geiser-debug-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    map)
  "Keymap for `geiser-debug-mode'.")

(define-derived-mode geiser-debug-mode nil "Geiser DBG"
  "A major mode for displaying Scheme compilation and evaluation results.
\\{geiser-debug-mode-map}"
  (buffer-disable-undo)
  (set-syntax-table scheme-mode-syntax-table)
  (setq next-error-function 'geiser-edit--open-next)
  (compilation-setup t)
  (setq buffer-read-only t))

(defvar-local geiser-debug--debugger-active-p nil)
(defvar-local geiser-debug--sender-buffer nil)

(defun geiser-debug--send-dbg (thing)
  (geiser-eval--send/wait (cons :debug (if (listp thing) thing (list thing)))))

(defun geiser-debug--debugger-display (thing ret)
  (geiser-debug--display-retort (format ",%s" thing)
                                ret
                                (geiser-eval--retort-result-str ret nil)))

(defun geiser-debug--send-to-repl (thing)
  (unless (and geiser-debug--debugger-active-p geiser-debug--sender-buffer)
    (error "Debugger not active"))
  (save-window-excursion
    (with-current-buffer geiser-debug--sender-buffer
      (when-let (ret (geiser-debug--send-dbg thing))
        (geiser-debug--debugger-display thing ret)))))

(defun geiser-debug-switch-to-buffer ()
  "Return to the scheme buffer that pooped this debug window."
  (interactive)
  (when geiser-debug--sender-buffer
    (geiser-repl--switch-to-buffer geiser-debug--sender-buffer)))

(defun geiser-debug-debugger-quit ()
  "Quit the current debugging session level."
  (interactive)
  (geiser-debug--send-to-repl 'quit))

(defun geiser-debug-debugger-backtrace ()
  "Quit the current debugging session level."
  (interactive)
  (geiser-debug--send-to-repl 'backtrace))

(defun geiser-debug-debugger-locals ()
  "Show local variables."
  (interactive)
  (geiser-debug--send-to-repl 'locals))

(defun geiser-debug-debugger-registers ()
  "Show register values."
  (interactive)
  (geiser-debug--send-to-repl 'registers))

(defun geiser-debug-debugger-error ()
  "Show error message."
  (interactive)
  (geiser-debug--send-to-repl 'error))

(transient-define-prefix geiser-debug--debugger-transient ()
  "Debugging meta-commands."
  [:description (lambda () (format "%s debugger" (geiser-impl--impl-str)))
   :if (lambda () geiser-debug--debugger-active-p)
   ["Display"
    ("b" "backtrace" geiser-debug-debugger-backtrace)
    ("e" "error" geiser-debug-debugger-error)
    ("l" "locals" geiser-debug-debugger-locals)
    ("r" " registers" geiser-debug-debugger-registers)]
   ["Go"
    ("jn" "Jump to next error" next-error)
    ("jp" "Jump to previous error" previous-error)
    ("x" "Exit debug level" geiser-debug-debugger-quit)]])

(geiser-menu--defmenu debug geiser-debug-mode-map
  ("Next error" ("n" [?\t]) compilation-next-error)
  ("Previous error" ("p" "\e\t" [backtab]) compilation-previous-error)
  ("Next error location" ((kbd "M-n")) next-error)
  ("Previous error location" ((kbd "M-p")) previous-error)
  ("Debugger command ..." "," geiser-debug--debugger-transient
   :enable geiser-debug--debugger-active-p)
  ("Source buffer" ("z" (kbd "C-c C-z")) geiser-debug-switch-to-buffer)
  --
  ("Quit" nil View-quit))


;;; Implementation-dependent functionality
(geiser-impl--define-caller geiser-debug--clean-up-output clean-up-output (output)
  "Clean up output from an evaluation for display.")


;;; Buffer for displaying evaluation results:

(geiser-popup--define debug "*Geiser dbg*" geiser-debug-mode)


;;; Displaying retorts

(geiser-impl--define-caller geiser-debug--display-error
    display-error (module key message)
  "This method takes 3 parameters (a module name, the error key,
and the accompanying error message) and should display
(in the current buffer) a formatted version of the error. If the
error was successfully displayed, the call should evaluate to a
non-null value.")

(geiser-impl--define-caller geiser-debug--enter-debugger
    enter-debugger ()
  "This method is called upon entering the debugger, in the REPL
buffer.")

(defun geiser-debug--display-after (what)
  (or geiser-debug-always-display-sexp-after-p
      (>= (with-temp-buffer
            (insert what)
            (count-lines (point-min) (point-max)))
          geiser-debug-long-sexp-lines)))

(defun geiser-debug--insert-res (res)
  (let ((begin (point)))
    (insert res)
    (let ((end (point)))
      (goto-char begin)
      (let ((no (geiser-image--replace-images
                 t geiser-debug-auto-display-images-p)))
        (goto-char end)
        (newline 2)
        (and no (> no 0))))))

(declare-function switch-to-geiser "geiser-repl")

(defun geiser-debug--display-retort (what ret &optional res auto-p)
  (let* ((err (geiser-eval--retort-error ret))
         (key (geiser-eval--error-key err))
         (debug (alist-get 'debug ret))
         (impl geiser-impl--implementation)
         (output (geiser-eval--retort-output ret))
         (output (and (stringp output)
                      (not (string= output ""))
                      (or (geiser-debug--clean-up-output impl output) output)))
         (module (geiser-eval--get-module))
         (img nil)
         (dir default-directory)
         (buffer (current-buffer))
         (debug-entered (when debug (geiser-debug--enter-debugger impl)))
         (after (geiser-debug--display-after what)))
    (unless debug-entered
      (geiser-debug--with-buffer
        (when (and (not debug) geiser-debug--debugger-active-p)
          (message "Debugger exited"))
        (setq geiser-debug--debugger-active-p debug
              geiser-debug--sender-buffer buffer
              geiser-impl--implementation impl)
        (erase-buffer)
        (when dir (setq default-directory dir))
        (unless after (insert what "\n\n"))
        (setq img (when (and res (not err) (not debug))
                    (geiser-debug--insert-res res)))
        (when (or err key output)
          (or (geiser-debug--display-error impl module key output)
              (insert "\n" (if key (format "%s\n" key) "") output "\n")))
        (when after
          (goto-char (point-max))
          (insert "\nExpression evaluated was:\n\n")
          (insert what "\n"))
        (cl-case geiser-debug-treat-ansi-colors
          (colors (ansi-color-apply-on-region (point-min) (point-max)))
          (remove (ansi-color-filter-region (point-min) (point-max))))
        (goto-char (point-min)))
      (when (or img err output)
        (cond (geiser-debug-jump-to-debug-p
               (geiser-debug--pop-to-buffer))
              (geiser-debug-show-debug-p
               (display-buffer (geiser-debug--buffer))))
        (when (and err geiser-debug-auto-next-error-p)
          (ignore-errors (next-error))
          (message "=> %s" output))))))

(defsubst geiser-debug--wrap-region (str)
  (format "(begin %s\n)" str))

(defun geiser-debug--unwrap (str)
  (if (string-match "(begin[ \t\n\v\r]+\\(.+\\)*)" str)
      (match-string 1 str)
    str))

(defun geiser-debug--send-region (compile start end and-go wrap &optional nomsg)
  "Evaluate (or COMPILE) the region delimited by START and END.
The result of the evaluation is reported asynchronously, so this
call is not blocking. If AND-GO is t, also jump to the repl
buffer.  If WRAP is t, the region's content is wrapped in a begin
form.  The flag NOMSG can be used to avoid reporting of the
result in the minibuffer."
  (let* ((str (buffer-substring-no-properties start end))
         (wrapped (if wrap (geiser-debug--wrap-region str) str))
         (code `(,(if compile :comp :eval) (:scm ,wrapped)))
         (cont (lambda (ret)
                 (let ((res (geiser-eval--retort-result-str ret nil))
                       (err (geiser-eval--retort-error ret))
                       (scstr (geiser-syntax--scheme-str str)))
                   (when and-go (funcall and-go))
                   (when (not err)
                     (save-excursion
                       (goto-char (/ (+ end start) 2))
                       (geiser-autodoc--clean-cache))
                     (unless nomsg
                       (save-match-data
                         (when (string-match "\\(?:[ \t\n\r]+\\)\\'" res)
                           (setq res (replace-match "" t t res))))
                       (message "%s" res)))
                   (geiser-debug--display-retort scstr ret res)))))
    (geiser-eval--send code cont (current-buffer))))

(defun geiser-debug--send-region/wait (compile start end timeout)
  "Synchronous version of `geiser-debug--send-region', waiting and returning its result."
  (let* ((str (buffer-substring-no-properties start end))
         (wrapped (geiser-debug--wrap-region str))
         (code `(,(if compile :comp :eval) (:scm ,wrapped))))
    (message "evaluating: %s" code)
    (geiser-eval--send/wait code timeout)))

(defun geiser-debug--expand-region (start end all wrap)
  (let* ((str (buffer-substring-no-properties start end))
         (wrapped (if wrap (geiser-debug--wrap-region str) str))
         (code
          `(:eval (:ge macroexpand (quote (:scm ,wrapped)) ,(if all :t :f))))
         (cont (lambda (ret)
                 (let ((err (geiser-eval--retort-error ret))
                       (result (geiser-eval--retort-result ret)))
                   (if err
                       (geiser-debug--display-retort str ret)
                     (geiser-debug--with-buffer
                       (erase-buffer)
                       (insert (format "%s"
                                       (if wrap
                                           (geiser-debug--unwrap result)
                                         result)))
                       (goto-char (point-min)))
                     (geiser-debug--pop-to-buffer))))))
    (geiser-eval--send code cont (current-buffer))))


(provide 'geiser-debug)
