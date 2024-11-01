;;; ob-browser-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ob-browser" "ob-browser.el" (0 0 0 0))
;;; Generated autoloads from ob-browser.el

(defvar org-babel-default-header-args:browser '((:results . "file") (:exports . "results")) "\
Default arguments for evaluating a browser source block.")

(autoload 'org-babel-execute:browser "ob-browser" "\
Execute a browser block.

\(fn BODY PARAMS)" nil nil)

(add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

(eval-after-load "org" '(add-to-list 'org-src-lang-modes '("browser" . html)))

(register-definition-prefixes "ob-browser" '("ob-browser-base-dir"))

;;;***

;;;### (autoloads nil nil ("ob-browser-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ob-browser-autoloads.el ends here
