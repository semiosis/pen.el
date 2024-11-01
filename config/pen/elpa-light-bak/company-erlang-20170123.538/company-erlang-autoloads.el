;;; company-erlang-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-erlang" "company-erlang.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from company-erlang.el

(autoload 'company-erlang "company-erlang" "\
Company backend for erlang completions with company COMMAND and optional ARG as arguments another one will be IGNORED.

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-erlang-init "company-erlang" "\
Init company erlang backend." nil nil)

(register-definition-prefixes "company-erlang" '("company-erlang-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-erlang-autoloads.el ends here
