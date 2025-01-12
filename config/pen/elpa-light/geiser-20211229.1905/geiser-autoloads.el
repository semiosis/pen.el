;;; geiser-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser" "geiser.el" (0 0 0 0))
;;; Generated autoloads from geiser.el

(defconst geiser-elisp-dir (file-name-directory load-file-name) "\
Directory containing Geiser's Elisp files.")

(autoload 'geiser-version "geiser-version" "\
Echo Geiser's version." t)

(autoload 'geiser-unload "geiser-reload" "\
Unload all Geiser code." t)

(autoload 'geiser-reload "geiser-reload" "\
Reload Geiser code." t)

(autoload 'geiser "geiser-repl" "\
Start a Geiser REPL, or switch to a running one." t)

(autoload 'run-geiser "geiser-repl" "\
Start a Geiser REPL." t)

(autoload 'geiser-connect "geiser-repl" "\
Start a Geiser REPL connected to a remote server." t)

(autoload 'geiser-connect-local "geiser-repl" "\
Start a Geiser REPL connected to a remote server over a Unix-domain socket." t)

(autoload 'switch-to-geiser "geiser-repl" "\
Switch to a running one Geiser REPL." t)

(autoload 'geiser-mode "geiser-mode" "\
Minor mode adding Geiser REPL interaction to Scheme buffers." t)

(autoload 'turn-on-geiser-mode "geiser-mode" "\
Enable Geiser's mode (useful in Scheme buffers)." t)

(autoload 'turn-off-geiser-mode "geiser-mode" "\
Disable Geiser's mode (useful in Scheme buffers)." t)

(autoload 'geiser-activate-implementation "geiser-impl" "\
Register the given implementation as active.")

(autoload 'geiser-implementation-extension "geiser-impl" "\
Register a file extension as handled by a given implementation.")

(mapc (lambda (group) (custom-add-load group (symbol-name group)) (custom-add-load 'geiser (symbol-name group))) '(geiser geiser-repl geiser-autodoc geiser-doc geiser-debug geiser-faces geiser-mode geiser-image geiser-implementation geiser-xref))

(autoload 'geiser-mode--maybe-activate "geiser-mode")

(add-hook 'scheme-mode-hook 'geiser-mode--maybe-activate)

;;;***

;;;### (autoloads nil "geiser-autodoc" "geiser-autodoc.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-autodoc.el

(register-definition-prefixes "geiser-autodoc" '("geiser-autodoc-"))

;;;***

;;;### (autoloads nil "geiser-base" "geiser-base.el" (0 0 0 0))
;;; Generated autoloads from geiser-base.el

(register-definition-prefixes "geiser-base" '("geiser--"))

;;;***

;;;### (autoloads nil "geiser-company" "geiser-company.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-company.el

(register-definition-prefixes "geiser-company" '("geiser-company--"))

;;;***

;;;### (autoloads nil "geiser-compile" "geiser-compile.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-compile.el

(autoload 'geiser-add-to-load-path "geiser-compile" "\
Add a new directory to running Scheme's load path.
When called interactively, this function will ask for the path to
add, defaulting to the current buffer's directory.

\(fn PATH)" t nil)

(register-definition-prefixes "geiser-compile" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-completion" "geiser-completion.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-completion.el

(register-definition-prefixes "geiser-completion" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-connection" "geiser-connection.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-connection.el

(register-definition-prefixes "geiser-connection" '("geiser-con"))

;;;***

;;;### (autoloads nil "geiser-custom" "geiser-custom.el" (0 0 0 0))
;;; Generated autoloads from geiser-custom.el

(register-definition-prefixes "geiser-custom" '("geiser-custom-"))

;;;***

;;;### (autoloads nil "geiser-debug" "geiser-debug.el" (0 0 0 0))
;;; Generated autoloads from geiser-debug.el

(register-definition-prefixes "geiser-debug" '("geiser-debug-"))

;;;***

;;;### (autoloads nil "geiser-doc" "geiser-doc.el" (0 0 0 0))
;;; Generated autoloads from geiser-doc.el

(register-definition-prefixes "geiser-doc" '("geiser-doc-"))

;;;***

;;;### (autoloads nil "geiser-edit" "geiser-edit.el" (0 0 0 0))
;;; Generated autoloads from geiser-edit.el

(register-definition-prefixes "geiser-edit" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-eval" "geiser-eval.el" (0 0 0 0))
;;; Generated autoloads from geiser-eval.el

(register-definition-prefixes "geiser-eval" '("geiser-eval-"))

;;;***

;;;### (autoloads nil "geiser-image" "geiser-image.el" (0 0 0 0))
;;; Generated autoloads from geiser-image.el

(register-definition-prefixes "geiser-image" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-impl" "geiser-impl.el" (0 0 0 0))
;;; Generated autoloads from geiser-impl.el

(autoload 'geiser-impl--add-to-alist "geiser-impl" "\


\(fn KIND WHAT IMPL &optional APPEND)" nil nil)

(register-definition-prefixes "geiser-impl" '("define-geiser-implementation" "geiser-" "with--geiser-implementation"))

;;;***

;;;### (autoloads nil "geiser-log" "geiser-log.el" (0 0 0 0))
;;; Generated autoloads from geiser-log.el

(register-definition-prefixes "geiser-log" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-menu" "geiser-menu.el" (0 0 0 0))
;;; Generated autoloads from geiser-menu.el

(register-definition-prefixes "geiser-menu" '("geiser-menu--"))

;;;***

;;;### (autoloads nil "geiser-mode" "geiser-mode.el" (0 0 0 0))
;;; Generated autoloads from geiser-mode.el

(register-definition-prefixes "geiser-mode" '("geiser-" "turn-o"))

;;;***

;;;### (autoloads nil "geiser-popup" "geiser-popup.el" (0 0 0 0))
;;; Generated autoloads from geiser-popup.el

(register-definition-prefixes "geiser-popup" '("geiser-popup-"))

;;;***

;;;### (autoloads nil "geiser-reload" "geiser-reload.el" (0 0 0 0))
;;; Generated autoloads from geiser-reload.el

(register-definition-prefixes "geiser-reload" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-repl" "geiser-repl.el" (0 0 0 0))
;;; Generated autoloads from geiser-repl.el

(register-definition-prefixes "geiser-repl" '("geiser" "run-geiser" "switch-to-geiser"))

;;;***

;;;### (autoloads nil "geiser-syntax" "geiser-syntax.el" (0 0 0 0))
;;; Generated autoloads from geiser-syntax.el

(register-definition-prefixes "geiser-syntax" '("geiser-syntax--"))

;;;***

;;;### (autoloads nil "geiser-table" "geiser-table.el" (0 0 0 0))
;;; Generated autoloads from geiser-table.el

(register-definition-prefixes "geiser-table" '("geiser-table-"))

;;;***

;;;### (autoloads nil "geiser-xref" "geiser-xref.el" (0 0 0 0))
;;; Generated autoloads from geiser-xref.el

(register-definition-prefixes "geiser-xref" '("geiser-xref-"))

;;;***

;;;### (autoloads nil nil ("geiser-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-autoloads.el ends here
