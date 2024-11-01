;;; helm-navi-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-navi" "helm-navi.el" (0 0 0 0))
;;; Generated autoloads from helm-navi.el

(defalias 'helm-navi 'helm-navi-headings-and-keywords-current-buffer)

(autoload 'helm-navi-headings-and-keywords-current-buffer "helm-navi" "\
Show matches for all `navi-mode' keywords and `outshine' headings in current buffer." t nil)

(defalias 'helm-navi-headings 'helm-navi-headings-current-buffer)

(autoload 'helm-navi-headings-current-buffer "helm-navi" "\
Show matches for Outshine headings in current buffer." t nil)

(register-definition-prefixes "helm-navi" '("helm-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-navi-autoloads.el ends here
