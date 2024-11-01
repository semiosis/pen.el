;;; helm-fish-completion-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-fish-completion" "helm-fish-completion.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from helm-fish-completion.el

(autoload 'helm-fish-completion "helm-fish-completion" "\
Helm interface for fish completion.
This is mostly useful for `M-x shell'.
For Eshell, see `helm-fish-completion-make-eshell-source'." t nil)

(autoload 'helm-fish-completion-make-eshell-source "helm-fish-completion" "\
Make and return Helm sources for Eshell.
This is a good candidate for `helm-esh-pcomplete-build-source-fn'.
For `M-x shell', use `helm-fish-completion' instead." nil nil)

(register-definition-prefixes "helm-fish-completion" '("helm-fish-completion-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-fish-completion-autoloads.el ends here
