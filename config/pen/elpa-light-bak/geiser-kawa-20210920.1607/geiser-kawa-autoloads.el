;;; geiser-kawa-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-kawa" "geiser-kawa.el" (0 0 0 0))
;;; Generated autoloads from geiser-kawa.el

(register-definition-prefixes "geiser-kawa" '("geiser-kawa-" "kawa"))

;;;***

;;;### (autoloads nil "geiser-kawa-arglist" "geiser-kawa-arglist.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-kawa-arglist.el

(register-definition-prefixes "geiser-kawa-arglist" '("geiser-kawa-"))

;;;***

;;;### (autoloads nil "geiser-kawa-deps" "geiser-kawa-deps.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from geiser-kawa-deps.el

(register-definition-prefixes "geiser-kawa-deps" '("geiser-kawa-deps-mvnw-package--and-run-kawa"))

;;;***

;;;### (autoloads nil "geiser-kawa-devutil-complete" "geiser-kawa-devutil-complete.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-kawa-devutil-complete.el

(register-definition-prefixes "geiser-kawa-devutil-complete" '("geiser-kawa-devutil-complete-"))

;;;***

;;;### (autoloads nil "geiser-kawa-devutil-exprtree" "geiser-kawa-devutil-exprtree.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-kawa-devutil-exprtree.el

(register-definition-prefixes "geiser-kawa-devutil-exprtree" '("geiser-kawa-devutil-exprtree-"))

;;;***

;;;### (autoloads nil "geiser-kawa-ext-help" "geiser-kawa-ext-help.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-kawa-ext-help.el

(register-definition-prefixes "geiser-kawa-ext-help" '("geiser-kawa-manual--"))

;;;***

;;;### (autoloads nil "geiser-kawa-globals" "geiser-kawa-globals.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-kawa-globals.el

(defconst geiser-kawa-elisp-dir (file-name-directory (or load-file-name (buffer-file-name))) "\
Directory containing geiser-kawa's Elisp files.")

(defconst geiser-kawa-dir (if (string-suffix-p "elisp/" geiser-kawa-elisp-dir) (expand-file-name "../" geiser-kawa-elisp-dir) geiser-kawa-elisp-dir) "\
Directory where geiser-kawa is located.")

(autoload 'run-kawa "geiser-kawa" "\
Start a Geiser Kawa Scheme REPL." t)

(autoload 'switch-to-kawa "geiser-kawa" "\
Start a Geiser Kawa Scheme REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-kawa-globals" '("geiser-kawa-"))

;;;***

;;;### (autoloads nil "geiser-kawa-util" "geiser-kawa-util.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from geiser-kawa-util.el

(register-definition-prefixes "geiser-kawa-util" '("geiser-kawa-util--"))

;;;***

;;;### (autoloads nil nil ("geiser-kawa-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-kawa-autoloads.el ends here
