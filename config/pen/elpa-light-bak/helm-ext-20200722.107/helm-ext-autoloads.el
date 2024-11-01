;;; helm-ext-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-ext" "helm-ext.el" (0 0 0 0))
;;; Generated autoloads from helm-ext.el

(autoload 'helm-ext-ff-enable-zsh-path-expansion "helm-ext" "\


\(fn ENABLE)" t nil)

(autoload 'helm-ext-ff-enable-auto-path-expansion "helm-ext" "\


\(fn ENABLE)" t nil)

(autoload 'helm-ext-ff-enable-skipping-dots "helm-ext" "\


\(fn ENABLE)" t nil)

(autoload 'helm-ext-ff-enable-split-actions "helm-ext" "\


\(fn ENABLE)" t nil)

(autoload 'helm-ext-minibuffer-enable-header-line-maybe "helm-ext" "\


\(fn ENABLE)" nil nil)

;;;***

;;;### (autoloads nil "helm-ext-ff" "helm-ext-ff.el" (0 0 0 0))
;;; Generated autoloads from helm-ext-ff.el

(autoload 'helm-ext-ff-define-split "helm-ext-ff" "\


\(fn NAME TYPE FIND-FUNC &optional BALANCE-P)" nil t)

(function-put 'helm-ext-ff-define-split 'lisp-indent-function '2)

(register-definition-prefixes "helm-ext-ff" '("helm-ext-f"))

;;;***

;;;### (autoloads nil "helm-ext-minibuffer" "helm-ext-minibuffer.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from helm-ext-minibuffer.el

(register-definition-prefixes "helm-ext-minibuffer" '("helm-ext--use-header-line-maybe"))

;;;***

;;;### (autoloads nil nil ("helm-ext-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-ext-autoloads.el ends here
