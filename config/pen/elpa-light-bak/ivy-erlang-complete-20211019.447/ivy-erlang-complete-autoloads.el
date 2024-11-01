;;; ivy-erlang-complete-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "ivy-erlang-complete" "ivy-erlang-complete.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from ivy-erlang-complete.el

(autoload 'ivy-erlang-complete-autosetup-project-root "ivy-erlang-complete" "\
Automatically setup, and return, erlang project root." t nil)

(autoload 'ivy-erlang-complete-init "ivy-erlang-complete" "\
Config ivy-erlang-complete by default." t nil)

(autoload 'ivy-erlang-complete-show-doc-at-point "ivy-erlang-complete" "\
Show doc for function from standart library." t nil)

(autoload 'ivy-erlang-complete-reparse "ivy-erlang-complete" "\
Reparse macros and recors for completion in current buffer." t nil)

(autoload 'ivy-erlang-complete-set-project-root "ivy-erlang-complete" "\
Set root for current project." t nil)

(autoload 'ivy-erlang-complete "ivy-erlang-complete" "\
Erlang completion at point." t nil)

(autoload 'ivy-erlang-complete--find-definition "ivy-erlang-complete" "\
Search THING definition in DIRECTORY-PATH.

\(fn THING)" nil nil)

(autoload 'ivy-erlang-complete-find-spec "ivy-erlang-complete" "\
Find spec at point.  It also find callback definition." t nil)

(autoload 'ivy-erlang-complete-find-definition "ivy-erlang-complete" "\
Find erlang definition." t nil)

(autoload 'ivy-erlang-complete-find-references "ivy-erlang-complete" "\
Find erlang references." t nil)

(autoload 'ivy-erlang-complete-find-file "ivy-erlang-complete" "\
Find file in current project." t nil)

(register-definition-prefixes "ivy-erlang-complete" '("ivy-erlang-complete-"))

;;;***

;;;### (autoloads nil nil ("ivy-erlang-complete-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ivy-erlang-complete-autoloads.el ends here
