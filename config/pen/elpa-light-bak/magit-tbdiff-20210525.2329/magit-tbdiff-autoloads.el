;;; magit-tbdiff-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-tbdiff" "magit-tbdiff.el" (0 0 0 0))
;;; Generated autoloads from magit-tbdiff.el

(autoload 'magit-tbdiff-ranges "magit-tbdiff" "\
Compare commits in RANGE-A with those in RANGE-B.
$ git range-diff [ARGS...] RANGE-A RANGE-B

\(fn RANGE-A RANGE-B &optional ARGS)" t nil)

(autoload 'magit-tbdiff-revs "magit-tbdiff" "\
Compare commits in REV-B..REV-A with those in REV-A..REV-B.
$ git range-diff [ARGS...] REV-B..REV-A REV-A..REV-B

\(fn REV-A REV-B &optional ARGS)" t nil)

(autoload 'magit-tbdiff-revs-with-base "magit-tbdiff" "\
Compare commits in BASE..REV-A with those in BASE..REV-B.
$ git range-diff [ARGS...] BASE..REV-A BASE..REV-B

\(fn REV-A REV-B BASE &optional ARGS)" t nil)
 (autoload 'magit-tbdiff "magit-tbdiff" nil t)

(eval-after-load 'magit '(progn (transient-append-suffix 'magit-diff "p" '("i" "Interdiffs" magit-tbdiff))))

(register-definition-prefixes "magit-tbdiff" '("magit-tbdiff-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-tbdiff-autoloads.el ends here
