;; This allows me to make arbitrary interpreters in the shebang line
;; #!$HOME/scripts/cr kotlin
;; I think this has prevented shebang without env from working. I have to fix this.
;; This one does not work for non-env shebangs!!
;; (setq auto-mode-interpreter-regexp (purecopy "#![ \t]?\\([^ \t\n]*[^ \t]+[ \t]\\)?\\([^\n]+\\)"))
;; This one does not work for env shebangs!!
;;(setq auto-mode-interpreter-regexp (purecopy "#![ \t]?\\([^ \t\n]*\\n/bin/env[ \t]\\)?\\([^ \t\n]+\\)"))

;; This uses an anonymous capture group to explicity tell emacs I want
;; to make the 2nd caputre group the 3rd one defined.
;; this should work for /bin/bash as well as /bin/env bash as well as
;; /usr/bin/env bash
;; (setq auto-mode-interpreter-regexp (purecopy "#![ \t]?\\(\\(/usr\\)?/bin/env[ \t]\\)?\\(?2:[^ \t\n]+\\)"))
(setq auto-mode-interpreter-regexp (purecopy "#![ \t]?\\(\\(/usr\\)?/bin/env[ \t]\\(-S \\)?\\)?\\(?2:[^ \t\n]+\\)"))

(add-to-list 'interpreter-mode-alist '("ruby" . ruby-mode))
;; (add-to-list 'interpreter-mode-alist '("cr kotlin" . kotlin-mode))
(add-to-list 'interpreter-mode-alist '("kotlin" . kotlin-mode))
(add-to-list 'interpreter-mode-alist '("mypython" . python-mode))
(add-to-list 'interpreter-mode-alist '("clojure" . clojure-mode))
(add-to-list 'interpreter-mode-alist '("emacs" . emacs-lisp-mode))
;; (add-to-list 'interpreter-mode-alist '("kotlin-script" . kotlin-mode))

(add-to-list 'interpreter-mode-alist '("emacs-script" . emacs-lisp-mode))
(add-to-list 'interpreter-mode-alist '("emacs-script-debug" . emacs-lisp-mode))

;; We already have one for bash
;; (add-to-list 'interpreter-mode-alist '("r?bash" . sh-mode))

;; Unfortunately, there are is also a local version of find-file-hook I have to deal with
;; (remove-hook 'find-file-hook 'insert-shebang)

;; This should do the trick
(defun insert-shebang ())

(provide 'pen-shebang)