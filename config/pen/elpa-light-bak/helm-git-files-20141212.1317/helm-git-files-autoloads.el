;;; helm-git-files-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "helm-git-files" "helm-git-files.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from helm-git-files.el

(autoload 'helm-git-files:git-p "helm-git-files" "\


\(fn &optional ROOT)" nil nil)

(defvar helm-git-files:modified-source nil)

(defvar helm-git-files:untracked-source nil)

(defvar helm-git-files:all-source nil)

(autoload 'helm-git-files:submodule-sources "helm-git-files" "\


\(fn KINDS &optional ROOT)" nil nil)

(autoload 'helm-git-files "helm-git-files" "\
`helm' for opening files managed by Git." t nil)

(register-definition-prefixes "helm-git-files" '("helm-git-files:"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; helm-git-files-autoloads.el ends here
