;;; auto-minor-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "auto-minor-mode" "auto-minor-mode.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from auto-minor-mode.el

(defvar auto-minor-mode-alist nil "\
Alist of filename patterns vs corresponding minor mode functions.

This is an equivalent of ‘auto-mode-alist’, for minor modes.

Unlike ‘auto-mode-alist’, matching is always case-folded.")

(defvar auto-minor-mode-magic-alist nil "\
Alist of buffer beginnings vs corresponding minor mode functions.

This is an equivalent of ‘magic-mode-alist’, for minor modes.

Magic minor modes are applied after ‘set-auto-mode’ enables any
major mode, so it’s possible to check for expected major modes in
match functions.

Unlike ‘magic-mode-alist’, matching is always case-folded.")

(autoload 'auto-minor-mode-set "auto-minor-mode" "\
Enable all minor modes appropriate for the current buffer.

If the optional argument KEEP-MODE-IF-SAME is non-nil, then we
don’t re-activate minor modes already enabled in the buffer.

\(fn &optional KEEP-MODE-IF-SAME)" nil nil)

(advice-add #'set-auto-mode :after #'auto-minor-mode-set)

(register-definition-prefixes "auto-minor-mode" '("auto-minor-mode-"))

;;;***

;;;### (autoloads nil nil ("auto-minor-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; auto-minor-mode-autoloads.el ends here
