;;; consult-notmuch-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "consult-notmuch" "consult-notmuch.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from consult-notmuch.el

(autoload 'consult-notmuch "consult-notmuch" "\
Search for your email in notmuch, showing single messages.
If given, use INITIAL as the starting point of the query.

\(fn &optional INITIAL)" t nil)

(autoload 'consult-notmuch-tree "consult-notmuch" "\
Search for your email in notmuch, showing full candidate tree.
If given, use INITIAL as the starting point of the query.

\(fn &optional INITIAL)" t nil)

(autoload 'consult-notmuch-address "consult-notmuch" "\
Search the notmuch db for an email address and compose mail to it.
With a prefix argument, prompt multiple times until there
is an empty input.

\(fn &optional MULTI-SELECT-P INITIAL-ADDR)" t nil)

(defvar consult-notmuch-buffer-source '(:name "Notmuch Buffer" :narrow (110 . "Notmuch") :hidden t :category buffer :face consult-buffer :history buffer-name-history :state consult--buffer-state :items consult-notmuch--interesting-buffers) "\
Notmuch buffer candidate source for `consult-buffer'.")

(register-definition-prefixes "consult-notmuch" '("consult-notmuch-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; consult-notmuch-autoloads.el ends here
