;;; clomacs-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "clomacs" "clomacs.el" (0 0 0 0))
;;; Generated autoloads from clomacs.el

(autoload 'clomacs-def "clomacs" "\
Wrap CL-ENTITY-NAME, evaluated on clojure side by EL-ENTITY-NAME.
DOC - optional elisp function docstring (when nil it constructed from
underlying clojure entity docstring if possible).
TYPE possible values are listed in the CLOMACS-POSSIBLE-RETURN-TYPES,
or it may be a custom function (:string by default).

\(fn EL-ENTITY-NAME CL-ENTITY-NAME &key (DOC nil) (TYPE :string) LIB-NAME NAMESPACE NREPL-READY-CALLBACK (BACKEND :clj))" nil t)

(autoload 'clomacs-defun "clomacs" "\
Wrap CL-FUNC-NAME, evaluated on clojure side by EL-FUNC-NAME.
CALL-TYPE - call Clojure side :sync or :async.
CALLBACK - callback function for :async CALL-TYPE case.
DOC - optional elisp function docstring (when nil it constructed from
underlying clojure entity docstring if possible).
INTERACTIVE - when defined and is a boolean `t` mark function (interactive),
if not boolean - insert interactive value into the function beginning as is.
RETURN-TYPE possible values are listed in the CLOMACS-POSSIBLE-RETURN-TYPES,
or it may be a custom function (:string by default).
RETURN-VALUE may be :value or :stdout (:value by default).
LIB-NAME - Elisp library name used in end-user .emacs config by `require'.
HTTPD-STARTER - in the case Clojure side code needs to call Elisp side code,
http-server should be started to pass http requests from Clojure REPL
to Emacs. This parameter is Elisp function to do it. Such function can
be created by `clomacs-create-httpd-start' macro.
NREPL-READY-CALLBACK in case of wrapped function called when nREPL not
started yet, a labmbda with one parameter - the result of wrapped function
evaluation can be added and executed.

\(fn EL-FUNC-NAME CL-FUNC-NAME &key (CALL-TYPE :sync) (CALLBACK nil) (DOC nil) (INTERACTIVE nil) (RETURN-TYPE :string) (RETURN-VALUE :value) LIB-NAME NAMESPACE (HTTPD-STARTER nil) NREPL-READY-CALLBACK (BACKEND :clj))" nil t)

(register-definition-prefixes "clomacs" '("clomacs-" "execute"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; clomacs-autoloads.el ends here
