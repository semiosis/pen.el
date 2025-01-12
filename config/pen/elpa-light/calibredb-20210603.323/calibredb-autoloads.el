;;; calibredb-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "calibredb" "calibredb.el" (0 0 0 0))
;;; Generated autoloads from calibredb.el

(autoload 'calibredb "calibredb" "\
Enter calibre Search Buffer." t nil)

;;;***

;;;### (autoloads nil "calibredb-annotation" "calibredb-annotation.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from calibredb-annotation.el

(register-definition-prefixes "calibredb-annotation" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-core" "calibredb-core.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from calibredb-core.el

(register-definition-prefixes "calibredb-core" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-helm" "calibredb-helm.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from calibredb-helm.el

(register-definition-prefixes "calibredb-helm" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-ivy" "calibredb-ivy.el" (0 0 0 0))
;;; Generated autoloads from calibredb-ivy.el

(autoload 'calibredb-find-counsel "calibredb-ivy" "\
Use counsel to list all ebooks details." t nil)

(register-definition-prefixes "calibredb-ivy" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-library" "calibredb-library.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from calibredb-library.el

(autoload 'calibredb-switch-library "calibredb-library" "\
Swich Calibre Library." t nil)

(autoload 'calibredb-library-list "calibredb-library" "\
Switch library from variable `calibredb-library-alist'.
If under *calibredb-search* buffer, it will auto refresh after
selecting the new item." t nil)

(register-definition-prefixes "calibredb-library" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-org" "calibredb-org.el" (0 0 0 0))
;;; Generated autoloads from calibredb-org.el

(autoload 'calibredb-org-link-view "calibredb-org" "\
Follow calibredb org links.

\(fn ID _)" nil nil)

(autoload 'calibredb-org-complete-link "calibredb-org" "\
Define completion for Org \"calibredb:\" links.
The optional PREFIX argument is ignored.
Please notice: `calibredb-id-width' must >= the real id lenth.

\(fn &optional PREFIX)" nil nil)

(register-definition-prefixes "calibredb-org" '("calibredb-org-link-copy"))

;;;***

;;;### (autoloads nil "calibredb-search" "calibredb-search.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from calibredb-search.el

(register-definition-prefixes "calibredb-search" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-show" "calibredb-show.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from calibredb-show.el

(register-definition-prefixes "calibredb-show" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-transient" "calibredb-transient.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from calibredb-transient.el

(register-definition-prefixes "calibredb-transient" '("calibredb-"))

;;;***

;;;### (autoloads nil "calibredb-utils" "calibredb-utils.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from calibredb-utils.el

(autoload 'calibredb-list "calibredb-utils" "\
Generate an org buffer which contain all ebooks' cover image, title and the file link." t nil)

(register-definition-prefixes "calibredb-utils" '("calibredb-"))

;;;***

;;;### (autoloads nil nil ("calibredb-faces.el" "calibredb-pkg.el")
;;;;;;  (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; calibredb-autoloads.el ends here
