;;; mu4e-query-fragments-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from mu4e-query-fragments.el

(defvar mu4e-query-fragments-list nil "\
Define query fragments available in `mu4e' searches and bookmarks.
List of (FRAGMENT . EXPANSION), where FRAGMENT is the string to be
substituted and EXPANSION is the query string to be expanded.

FRAGMENT should be an unique text symbol that doesn't conflict with the
regular mu4e/xapian search syntax or previous fragments. EXPANSION is
expanded as (EXPANSION), composing properly with boolean operators and
can contain fragments in itself.

Example:

(setq mu4e-query-fragments-list
   '((\"%junk\" . \"maildir:/Junk OR subject:SPAM\")
     (\"%hidden\" . \"flag:trashed OR %junk\")))")
(custom-autoload 'mu4e-query-fragments-list "mu4e-query-fragments" t)
(defvar mu4e-query-fragments-append nil "\
Query fragment appended to new searches by `mu4e-query-fragments-search'.")
(custom-autoload 'mu4e-query-fragments-append "mu4e-query-fragments" t)
(autoload 'mu4e-query-fragments-expand "mu4e-query-fragments" "\
Expand fragments defined in `mu4e-query-fragments-list' in QUERY.

(fn QUERY)" t)
(register-definition-prefixes "mu4e-query-fragments" '("mu4e-query-fragments-"))

;;; End of scraped data

(provide 'mu4e-query-fragments-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; mu4e-query-fragments-autoloads.el ends here
