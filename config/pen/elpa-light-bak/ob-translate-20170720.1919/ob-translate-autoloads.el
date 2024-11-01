;;; ob-translate-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ob-translate" "ob-translate.el" (0 0 0 0))
;;; Generated autoloads from ob-translate.el

(autoload 'org-babel-execute:translate "ob-translate" "\
org-babel translation hook.

\(fn BODY PARAMS)" nil nil)

(eval-after-load "org" '(add-to-list 'org-src-lang-modes '("translate" . text)))

(register-definition-prefixes "ob-translate" '("ob-translate:"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ob-translate-autoloads.el ends here
