;;; evil-commentary-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-commentary" "evil-commentary.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from evil-commentary.el

(defvar evil-commentary-mode nil "\
Non-nil if Evil-Commentary mode is enabled.
See the `evil-commentary-mode' command
for a description of this minor mode.")

(custom-autoload 'evil-commentary-mode "evil-commentary" nil)

(autoload 'evil-commentary-mode "evil-commentary" "\
Commentary mode.

If called interactively, toggle `Evil-Commentary mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "evil-commentary" '("evil-commentary-comment-function-for-mode-alist"))

;;;***

;;;### (autoloads nil "evil-commentary-integration" "evil-commentary-integration.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from evil-commentary-integration.el

(autoload 'evil-commentary/org-comment-or-uncomment-region "evil-commentary-integration" "\
Comment function for `org-mode'.

\(fn BEG END)" t nil)

(register-definition-prefixes "evil-commentary-integration" '("evil-commentary/org-babel-do-in-edit-buffer"))

;;;***

;;;### (autoloads nil nil ("evil-commentary-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-commentary-autoloads.el ends here
