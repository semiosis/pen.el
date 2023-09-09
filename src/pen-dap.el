(require 'dap-ui)
(require 'dap-mouse)

(use-package dap-mode
  :ensure t :after lsp-mode
  :config
  (dap-mode t)
  (dap-ui-mode t))

(require 'pen-lsp-java)

(dap-tooltip-mode 1)
;; use tooltips for mouse hover
;; if it is not enabled `dap-mode' will use the minibuffer.
(tooltip-mode 1)

(defun dap-debug-and-hydra ()
  (interactive)
  (call-interactively 'dap-debug)
  (call-interactively 'dap-hydra/body))

(defun dap-java-debug-and-hydra ()
  (interactive)
  (call-interactively 'dap-java-debug)
  (call-interactively 'dap-hydra/body))

(require 'dap-python)

(advice-add 'dap-ui--clear-breakpoint-overlays :around #'ignore-errors-around-advice)

;; (setq dap-python-terminal "xt")
(setq dap-python-terminal "")

(defun dap-python--populate-start-file-args (conf)
  "Populate CONF with the required arguments."
  (let* ((python-executable (dap-python--pyenv-executable-find dap-python-executable))
         (python-args (plist-get conf :args))
         (program (or (plist-get conf :target-module)
                      (plist-get conf :program)
                      (buffer-file-name)))
         (module (plist-get conf :module))
         (debugger (plist-get conf :debugger)))
    ;; These are `dap-python'-specific and always ignored.
    (cl-remf conf :debugger)
    (cl-remf conf :target-module)

    ;; Ignored by ptsvd and set explicitly for debugpy.
    (cl-remf conf :program)
    (pcase (or debugger dap-python-debugger)
      ((or 'ptvsd "ptvsd")
       (let ((host "localhost")
             (debug-port (dap--find-available-port)))
         ;; support :args ["foo" "bar"]; NOTE: :args can be nil; however, nil is
         ;; a list, so it will be mapconcat'ed, yielding the empty string.
         (when (sequencep python-args)
           (setq python-args (mapconcat #'shell-quote-argument python-args " ")))
         ;; ignored by ptsvd anyway
         (cl-remf conf :module)
         (cl-remf conf :args)
         (plist-put conf :program-to-start
                    (format "%s %s -m ptvsd --wait --host %s --port %s%s %s%s"
                            (or dap-python-terminal "")
                            (shell-quote-argument python-executable)
                            host
                            debug-port
                            (if module (concat " -m " (shell-quote-argument module)) "")
                            (if program (shell-quote-argument program) "")
                            (if (not (string-empty-p python-args)) (concat " " python-args) "")))
         (plist-put conf :debugServer debug-port)
         (plist-put conf :port debug-port)
         (plist-put conf :hostName host)
         (plist-put conf :host host)))
      ((or 'debugpy "debugpy")
       (cond ((stringp python-args)
              (cl-callf split-string-and-unquote python-args))
             ;; If both :module and :program are specified, we'll need to push
             ;; :program to PYTHON-ARGS instead, to behave like ptvsd. This is
             ;; needed for the debug-test-at-point functionality.
             ((and (vectorp python-args) module program)
              (cl-callf cl-coerce python-args 'list)))

       ;; If certain properties are nil, issues will arise, as debugpy expects
       ;; them to unspecified instead. Some templates in this file set such
       ;; properties (e.g. :module) to nil instead of leaving them undefined. To
       ;; support them, sanitize CONF before passing it on.
       (when program
         (if module
             (push program python-args)
           (plist-put conf :program program)))

       (cl-remf conf :args)
       (plist-put conf :args (or python-args []))

       (unless module
         (cl-remf conf :module))

       (unless (plist-get conf :cwd)
         (cl-remf conf :cwd))

       (plist-put conf :dap-server-path
                  (list python-executable "-m" "debugpy.adapter")))
      (_ (error "`dap-python': unknown :debugger type %S" debugger)))
    conf))

;; automatically trigger the hydra when the program hits a breakpoint by using the following code.
(add-hook 'dap-stopped-hook
          (λ (arg) (call-interactively #'dap-hydra)))

(provide 'pen-dap)