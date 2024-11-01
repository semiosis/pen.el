;;; helm-lean-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-lean" "helm-lean.el" (0 0 0 0))
;;; Generated autoloads from helm-lean.el

(autoload 'helm-lean-definitions "helm-lean" "\
Open a 'helm' interface for searching Lean definitions." t nil)

(autoload 'helm-lean-hook "helm-lean" "\
Set up helm-lean for current buffer" nil nil)

(add-hook 'lean-mode-hook #'helm-lean-hook)

(register-definition-prefixes "helm-lean" '("helm-lean-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-lean-autoloads.el ends here
