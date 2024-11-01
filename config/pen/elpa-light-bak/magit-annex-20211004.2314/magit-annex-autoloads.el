;;; magit-annex-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-annex" "magit-annex.el" (0 0 0 0))
;;; Generated autoloads from magit-annex.el
 (autoload 'magit-annex-dispatch "magit-annex" nil t)

(eval-after-load 'magit '(progn (define-key magit-mode-map "@" 'magit-annex-dispatch-or-init) (transient-append-suffix 'magit-dispatch '(0 -1 -1) '("@" "Annex" magit-annex-dispatch-or-init))))

(autoload 'magit-annex-dispatch-or-init "magit-annex" "\
Call `magit-annex-dispatch' or offer to initialize non-annex repo." t nil)

(autoload 'magit-annex-init "magit-annex" "\
Initialize git-annex repository.
\('git annex init [DESCRIPTION]')

\(fn &optional DESCRIPTION)" t nil)

(autoload 'magit-annex-unused-in-refs "magit-annex" "\
Show annex files not used in any branches or tags.
These files are not pointed by the tips of the repositories
branches or tags.
\('git annex unused [ARGS]')

\(fn &optional ARGS)" t nil)

(autoload 'magit-annex-unused-in-reflog "magit-annex" "\
Show annex files not used in any of the revisions in HEAD's reflog.
\('git annex unused --used-refspec=reflog [ARGS]')

\(fn &optional ARGS)" t nil)

(autoload 'magit-annex-list-files "magit-annex" "\
List annex files.
\('git annex list [ARGS]')

\(fn &optional ARGS)" t nil)

(autoload 'magit-annex-list-dir-files "magit-annex" "\
List annex files in DIRECTORY.
\('git annex list [ARGS] DIRECTORY')

\(fn DIRECTORY &optional ARGS)" t nil)

(register-definition-prefixes "magit-annex" '("magit-annex-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-annex-autoloads.el ends here
