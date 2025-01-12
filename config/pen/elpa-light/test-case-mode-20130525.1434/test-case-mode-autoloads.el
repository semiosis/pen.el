;;; test-case-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "test-case-mode" "test-case-mode.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from test-case-mode.el

(autoload 'test-case-mode "test-case-mode" "\
A minor mode for test buffers.
Tests can be started with the commands `test-case-run' or
`test-case-run-all'.  If you want to run tests automatically after a
compilation, use `test-case-compilation-finish-run-all'.

If called interactively, toggle `Test-Case mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

When a run has finished, the results appear in a buffer named \"*Test
Result*\".  Clicking on the files will take you to the failure location,
as will `next-error' and `previous-error'.

Failures are also highlighted in the buffer.  Hovering the mouse above
them, or enabling `test-case-echo-failure-mode' shows the associated
failure message.

The testing states are indicated visually.  The buffer name is colored
according to the result and a dot in the mode-line represents the global
state.  This behavior is customizable through `test-case-color-buffer-id'
and `test-case-mode-line-info-position'.

\(fn &optional ARG)" t nil)

(autoload 'enable-test-case-mode-if-test "test-case-mode" "\
Turns on ``test-case-mode'' if this buffer is a recognized test." nil nil)
(add-hook 'find-file-hook 'enable-test-case-mode-if-test)

(autoload 'test-case-find-all-tests "test-case-mode" "\
Find all test cases in DIRECTORY.

\(fn DIRECTORY)" t nil)

(autoload 'test-case-compilation-finish-run-all "test-case-mode" "\
Post-compilation hook for running all tests after successful compilation.
Install this the following way:

\(add-hook 'compilation-finish-functions
          'test-case-compilation-finish-run-all)

\(fn BUFFER RESULT)" nil nil)

(register-definition-prefixes "test-case-mode" '("disable-test-case-mode" "tast-case-menu-format-buffer" "test-case-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; test-case-mode-autoloads.el ends here
