;;; geiser-mode.el -- minor mode for scheme buffers

;; Copyright (C) 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2020 Jose Antonio Ortega Ruiz

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the Modified BSD License. You should
;; have received a copy of the license along with this program. If
;; not, see <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>.

;; Start date: Sun Feb 08, 2009 15:13


;;; Code:

(require 'geiser-repl)
(require 'geiser-menu)
(require 'geiser-doc)
(require 'geiser-compile)
(require 'geiser-completion)
(require 'geiser-company)
(require 'geiser-xref)
(require 'geiser-edit)
(require 'geiser-autodoc)
(require 'geiser-debug)
(require 'geiser-syntax)
(require 'geiser-impl)
(require 'geiser-eval)
(require 'geiser-popup)
(require 'geiser-custom)
(require 'geiser-base)


;;; Customization:

(defgroup geiser-mode nil
  "Mode enabling Geiser abilities in Scheme buffers &co.."
  :group 'geiser)

(geiser-custom--defcustom geiser-mode-auto-p t
  "Whether `geiser-mode' should be active by default in all scheme buffers."
  :group 'geiser-mode
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-start-repl-p nil
  "Whether a REPL should be automatically started if one is not
active when `geiser-mode' is activated in a buffer."
  :group 'geiser-mode
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-autodoc-p t
  "Whether `geiser-autodoc-mode' gets enabled by default in Scheme buffers."
  :group 'geiser-mode
  :group 'geiser-autodoc
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-company-p t
  "Whether to use company-mode for completion, if available."
  :group 'geiser-mode
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-smart-tab-p nil
  "Whether `geiser-smart-tab-mode' gets enabled by default in Scheme buffers."
  :group 'geiser-mode
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-eval-last-sexp-to-buffer nil
  "Whether `eval-last-sexp' prints results to buffer"
  :group 'geiser-mode
  :type 'boolean)

(geiser-custom--defcustom geiser-mode-eval-to-buffer-prefix " "
  "When `geiser-mode-eval-last-sexp-to-buffer', the prefix string
which will be prepended to results."
  :group 'geiser-mode
  :type 'string)

(geiser-custom--defcustom geiser-mode-eval-to-buffer-transformer nil
  "Transformer for results inserted in debug buffer.

When `geiser-mode-eval-last-sexp-to-buffer', the result will be
transformed using this function default behavior is just prepend
with `geiser-mode-eval-to-buffer-prefix' takes two arguments:
`msg' and `is-error?'  `msg' is the result string going to be
transformed, `is-error?' is a boolean indicating whether the
result is an error msg."
  :group 'geiser-mode
  :type 'function)



;;; Evaluation commands:

(defun geiser--go-to-repl ()
  (switch-to-geiser nil nil (current-buffer))
  (push-mark)
  (goto-char (point-max)))

(defun geiser-wait-eval (req timeout)
  "Use REQ, the result of computing an evaluation, to wait for its result.

TIMEOUT is the number of seconds to wait for evaluation
completion.  Functions returning a waitable REQ are
`geiser-eval-region' and its derivatives evaluating buffers or
individual sexps."
  (geiser-eval--wait req (* 1000 timeout)))

(defun geiser-eval-region (start end &optional and-go raw nomsg)
  "Eval the current region in the Geiser REPL.

With prefix, goes to the REPL buffer afterwards (as
`geiser-eval-region-and-go').  The evaluation is performed
asynchronously: this function's return value can be used to wait
for its completion using `geiser-eval-wait'.  See also
`geiser-eval-region/wait' if you just need to eval a region
programmatically in a synchronous way."
  (interactive "rP")
  (save-restriction
    (narrow-to-region start end)
    (check-parens))
  (geiser-debug--send-region nil
                             start
                             end
                             (and and-go 'geiser--go-to-repl)
                             (not raw)
                             nomsg))

(defun geiser-eval-region/wait (start end &optional timeout)
  "Like `geiser-eval-region', but waiting for the evaluation to finish.
Returns its raw result, rather than displaying it. TIMEOUT is the
number of seconds to wait for the evaluation to finish."
  (geiser-debug--send-region/wait nil start end (* 1000 (or timeout 10))))

(defun geiser-eval-region-and-go (start end)
  "Eval the current region in the Geiser REPL and visit it afterwads."
  (interactive "r")
  (geiser-eval-region start end t))

(geiser-impl--define-caller geiser-eval--bounds eval-bounds ()
  "A pair with the bounds of a buffer to be evaluated, defaulting
  to (cons (point-min) . (point-max)).")

(defun geiser-eval-buffer (&optional and-go raw nomsg)
  "Eval the current buffer in the Geiser REPL.

With prefix, goes to the REPL buffer afterwards (as
`geiser-eval-buffer-and-go')"
  (interactive "P")
  (let* ((bounds (geiser-eval--bounds geiser-impl--implementation))
         (from (or (car bounds) (point-min)))
         (to (or (cdr bounds) (point-max))))
    (geiser-eval-region from to and-go raw nomsg)))

(defun geiser-eval-buffer-and-go ()
  "Eval the current buffer in the Geiser REPL and visit it afterwads."
  (interactive)
  (geiser-eval-buffer t))

(defun geiser-eval-definition (&optional and-go)
  "Eval the current definition in the Geiser REPL.

With prefix, goes to the REPL buffer afterwards (as
`geiser-eval-definition-and-go')"
  (interactive "P")
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (geiser-eval-region (point) end and-go t))))

(defun geiser-eval-definition-and-go ()
  "Eval the current definition in the Geiser REPL and visit it afterwads."
  (interactive)
  (geiser-eval-definition t))

(defun geiser-eval-last-sexp (print-to-buffer-p)
  "Eval the previous sexp in the Geiser REPL.

With a prefix, revert the effect of `geiser-mode-eval-last-sexp-to-buffer' "
  (interactive "P")
  (let* (bosexp
         (eosexp (save-excursion (backward-sexp)
                                 (setq bosexp (point))
                                 (forward-sexp)
                                 (point)))
         (ret-transformer (or geiser-mode-eval-to-buffer-transformer
                              (lambda (msg is-error?)
                                (format "%s%s%s"
                                        geiser-mode-eval-to-buffer-prefix
                                        (if is-error? "ERROR" "")
                                        msg))))
         (ret (save-excursion
                (geiser-eval-region bosexp ;beginning of sexp
                                    eosexp ;end of sexp
                                    nil
                                    t
                                    print-to-buffer-p)))
         (err (geiser-eval--retort-error ret))
         (will-eval-to-buffer (if print-to-buffer-p
                                  (not geiser-mode-eval-last-sexp-to-buffer)
                                geiser-mode-eval-last-sexp-to-buffer))
         (str (geiser-eval--retort-result-str ret
                                              (when will-eval-to-buffer ""))))
    (cond  ((not will-eval-to-buffer) str)
           (err (insert (funcall ret-transformer
                                 (geiser-eval--error-str err) t)))
           ((string= "" str))
           (t (push-mark)
              (insert (funcall ret-transformer str nil))))))

(defun geiser-compile-definition (&optional and-go)
  "Compile the current definition in the Geiser REPL.

With prefix, goes to the REPL buffer afterwards (as
`geiser-eval-definition-and-go')"
  (interactive "P")
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (geiser-debug--send-region t
                                 (point)
                                 end
                                 (and and-go 'geiser--go-to-repl)
                                 t))))

(defun geiser-compile-definition-and-go ()
  "Compile the current definition in the Geiser REPL and visit it afterwads."
  (interactive)
  (geiser-compile-definition t))

(defun geiser-expand-region (start end &optional all raw)
  "Macro-expand the current region and display it in a buffer.
With prefix, recursively macro-expand the resulting expression."
  (interactive "rP")
  (geiser-debug--expand-region start end all (not raw)))

(defun geiser-expand-definition (&optional all)
  "Macro-expand the current definition.

With prefix, recursively macro-expand the resulting expression."
  (interactive "P")
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (geiser-expand-region (point) end all t))))

(defun geiser-expand-last-sexp (&optional all)
  "Macro-expand the previous sexp.

With prefix, recursively macro-expand the resulting expression."
  (interactive "P")
  (geiser-expand-region (save-excursion (backward-sexp) (point))
                        (point)
                        all
                        t))

(defun geiser-set-scheme ()
  "Associates current buffer with a given Scheme implementation."
  (interactive)
  (save-excursion
    (geiser-syntax--remove-kws)
    (let ((impl (geiser-impl--read-impl)))
      (geiser-impl--set-buffer-implementation impl)
      (geiser-repl--set-up-repl impl)
      (geiser-syntax--add-kws)
      (geiser-syntax--fontify))))

(defun geiser-mode-switch-to-repl (arg)
  "Switches to Geiser REPL.

With prefix, try to enter the current buffer's module."
  (interactive "P")
  (if arg
      (switch-to-geiser-module (geiser-eval--get-module) (current-buffer))
    (switch-to-geiser nil nil (current-buffer))))

(defun geiser-mode-switch-to-repl-and-enter ()
  "Switches to Geiser REPL and enters current buffer's module."
  (interactive)
  (geiser-mode-switch-to-repl t))

(defun geiser-restart-repl ()
  "Restarts the REPL associated with the current buffer."
  (interactive)
  (let ((b (current-buffer)))
    (geiser-mode-switch-to-repl nil)
    (comint-kill-subjob)
    (sit-for 0.1) ;; ugly hack; but i don't care enough to fix it
    (call-interactively 'run-geiser)
    (sit-for 0.2) ;; ditto
    (goto-char (point-max))
    (pop-to-buffer b)))

(defun geiser-exit-repl ()
  "Issues the command `geiser-repl-exit' in this buffer's associated REPL."
  (interactive)
  (geiser-repl--call-in-repl #'geiser-repl-exit))


;;; Keys:

(defvar geiser-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [menu-bar scheme] 'undefined)
    ;; (geiser-mode--triple-chord ?x ?m 'geiser-xref-generic-methods)

    (geiser-menu--defmenu geiserm map
      ("Eval sexp before point" "\C-x\C-e" geiser-eval-last-sexp)
      ("Eval definition" ("\M-\C-x" "\C-c\C-c") geiser-eval-definition)
      ("Eval definition and go" ("\C-c\M-e" "\C-c\M-e")
       geiser-eval-definition-and-go)
      ("Eval region" "\C-c\C-r" geiser-eval-region :enable mark-active)
      ("Eval region and go" "\C-c\M-r" geiser-eval-region-and-go
       geiser-eval-region :enable mark-active)
      ("Eval buffer" "\C-c\C-b" geiser-eval-buffer)
      ("Eval buffer and go" "\C-c\M-b" geiser-eval-buffer-and-go)
      ("Load scheme file..." "\C-c\C-l" geiser-load-file)
      ("Abort evaluation" ("\C-c\C-i" "\C-c\C-e\C-i" "\C-c\C-ei")
       geiser-eval-interrupt)
      (menu "Macroexpand"
            ("Sexp before point" ("\C-c\C-m\C-e" "\C-c\C-me")
             geiser-expand-last-sexp)
            ("Region" ("\C-c\C-m\C-r" "\C-c\C-mr") geiser-expand-region)
            ("Definition" ("\C-c\C-m\C-x" "\C-c\C-mx") geiser-expand-definition))
      --
      ("Symbol documentation" ("\C-c\C-d\C-d" "\C-c\C-dd")
       geiser-doc-symbol-at-point :enable (geiser--symbol-at-point))
      ("Short symbol documentation" ("\C-c\C-d\C-s" "\C-c\C-ds")
       geiser-autodoc-show :enable (geiser--symbol-at-point))
      ("Module documentation" ("\C-c\C-d\C-m" "\C-c\C-dm") geiser-doc-module)
      ("Symbol manual lookup" ("\C-c\C-d\C-i" "\C-c\C-di")
       geiser-doc-look-up-manual :enable (geiser-doc--manual-available-p))
      (mode "Autodoc mode" ("\C-c\C-d\C-a" "\C-c\C-da") geiser-autodoc-mode)
      --
      ("Compile buffer" "\C-c\C-k" geiser-compile-current-buffer)
      ("Switch to REPL" "\C-c\C-z" geiser-mode-switch-to-repl)
      ("Switch to REPL and enter module" "\C-c\C-a"
       geiser-mode-switch-to-repl-and-enter)
      ("Set Scheme..." "\C-c\C-s" geiser-set-scheme)
      ("Exit REPL or debugger" "\C-c\C-q" geiser-exit-repl)
      --
      ("Edit symbol at point" "\M-." geiser-edit-symbol-at-point
       :enable (geiser--symbol-at-point))
      ("Go to previous definition" "\M-," geiser-pop-symbol-stack)
      ("Complete symbol" ((kbd "M-TAB")) completion-at-point
       :enable (geiser--symbol-at-point))
      ("Complete module name" ((kbd "M-`") (kbd "C-."))
       geiser-completion--complete-module)
      ("Edit module" ("\C-c\C-e\C-m" "\C-c\C-em") geiser-edit-module)
      ("Add to load path..." ("\C-c\C-e\C-l" "\C-c\C-el") geiser-add-to-load-path)
      ("Toggle ()/[]" ("\C-c\C-e\C-[" "\C-c\C-e[") geiser-squarify)
      ("Insert λ" ("\C-c\\" "\C-c\C-\\") geiser-insert-lambda)
      --
      ("Callers" ((kbd "C-c <")) geiser-xref-callers
       :enable (and (geiser-eval--supported-p 'callers)
                    (geiser--symbol-at-point)))
      ("Callees" ((kbd "C-c >")) geiser-xref-callees
       :enable (and (geiser-eval--supported-p 'callees)
                    (geiser--symbol-at-point)))
      --
      (mode "Smart TAB mode" nil geiser-smart-tab-mode)
      --
      (custom "Customize Geiser mode" geiser-mode))
    map))


;;; Geiser mode:

(defvar-local geiser-mode-string nil
  "Modeline indicator for geiser-mode")

(defun geiser-mode--lighter ()
  (or geiser-mode-string
      (format " %s" (or (geiser-impl--impl-str) "G"))))

(define-minor-mode geiser-mode
  "Toggle Geiser's mode.

With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode.

When Geiser mode is enabled, a host of nice utilities for
interacting with the Geiser REPL is at your disposal.
\\{geiser-mode-map}"
  :init-value nil
  :lighter (:eval (geiser-mode--lighter))
  :group 'geiser-mode
  (when geiser-mode (geiser-impl--set-buffer-implementation nil t))
  (setq geiser-autodoc-mode-string "/A")
  (setq geiser-smart-tab-mode-string "/T")
  (geiser-company--setup (and geiser-mode geiser-mode-company-p))
  (geiser-completion--setup geiser-mode)
  (when geiser-mode-autodoc-p
    (geiser-autodoc-mode (if geiser-mode 1 -1)))
  (when geiser-mode-smart-tab-p
    (geiser-smart-tab-mode (if geiser-mode 1 -1)))
  (geiser-syntax--add-kws)
  (when (and geiser-mode
             geiser-mode-start-repl-p
             (not (geiser-syntax--font-lock-buffer-p))
             (not (geiser-repl--connection*)))
    (save-window-excursion (run-geiser geiser-impl--implementation))))

(defun turn-on-geiser-mode ()
  "Enable `geiser-mode' (in a Scheme buffer)."
  (interactive)
  (geiser-mode 1))

(defun turn-off-geiser-mode ()
  "Disable `geiser-mode' (in a Scheme buffer)."
  (interactive)
  (geiser-mode -1))

(defun geiser-mode--maybe-activate ()
  (when (and geiser-mode-auto-p (eq major-mode 'scheme-mode))
    (turn-on-geiser-mode)))


;;; Reload support:

(defun geiser-mode--buffers ()
  (let ((buffers))
    (dolist (buffer (buffer-list))
      (when (buffer-live-p buffer)
        (set-buffer buffer)
        (when geiser-mode
          (push (cons buffer geiser-impl--implementation) buffers))))
    buffers))

(defun geiser-mode--restore (buffers)
  (dolist (b buffers)
    (when (buffer-live-p (car b))
      (set-buffer (car b))
      (when (cdr b)
        (geiser-impl--set-buffer-implementation (cdr b)))
      (geiser-mode 1))))

(defun geiser-mode-unload-function ()
  (dolist (b (geiser-mode--buffers))
    (with-current-buffer (car b) (geiser-mode nil))))


(provide 'geiser-mode)
