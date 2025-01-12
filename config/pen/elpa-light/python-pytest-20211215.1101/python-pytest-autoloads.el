;;; python-pytest-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "python-pytest" "python-pytest.el" (0 0 0 0))
;;; Generated autoloads from python-pytest.el
 (autoload 'python-pytest-dispatch "python-pytest" nil t)

(autoload 'python-pytest "python-pytest" "\
Run pytest with ARGS.

With a prefix argument, allow editing.

\(fn &optional ARGS)" t nil)

(autoload 'python-pytest-file "python-pytest" "\
Run pytest on FILE, using ARGS.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn FILE &optional ARGS)" t nil)

(autoload 'python-pytest-file-dwim "python-pytest" "\
Run pytest on FILE, intelligently finding associated test modules.

When run interactively, this tries to work sensibly using
the current file.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn FILE &optional ARGS)" t nil)

(autoload 'python-pytest-files "python-pytest" "\
Run pytest on FILES, using ARGS.

When run interactively, this allows for interactive file selection.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn FILES &optional ARGS)" t nil)

(autoload 'python-pytest-directories "python-pytest" "\
Run pytest on DIRECTORIES, using ARGS.

When run interactively, this allows for interactive directory selection.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn DIRECTORIES &optional ARGS)" t nil)

(autoload 'python-pytest-function "python-pytest" "\
Run pytest on FILE with FUNC (or class).

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn FILE FUNC ARGS)" t nil)

(autoload 'python-pytest-function-dwim "python-pytest" "\
Run pytest on FILE with FUNC (or class).

When run interactively, this tries to work sensibly using
the current file and function around point.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn FILE FUNC ARGS)" t nil)

(autoload 'python-pytest-last-failed "python-pytest" "\
Run pytest, only executing previous test failures.

Additional ARGS are passed along to pytest.
With a prefix argument, allow editing.

\(fn &optional ARGS)" t nil)

(autoload 'python-pytest-repeat "python-pytest" "\
Run pytest with the same argument as the most recent invocation.

With a prefix ARG, allow editing." t nil)

(register-definition-prefixes "python-pytest" '("python-pytest-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; python-pytest-autoloads.el ends here
