;;; counsel-test-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "counsel-test-core" "counsel-test-core.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from counsel-test-core.el

(register-definition-prefixes "counsel-test-core" '("counsel-test"))

;;;***

;;;### (autoloads nil "counsel-test-ctest" "counsel-test-ctest.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from counsel-test-ctest.el

(autoload 'counsel-test-ctest "counsel-test-ctest" "\
Browse and execute ctest tests.

If the value of `counsel-test-dir' is not set (e.g. nil) prompt user for the
ctest directory.

With a prefix argument ARG also force prompt user for this directory.

\(fn ARG)" t nil)

(register-definition-prefixes "counsel-test-ctest" '("counsel-test-ctest-"))

;;;***

;;;### (autoloads nil "counsel-test-pytest" "counsel-test-pytest.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from counsel-test-pytest.el

(autoload 'counsel-test-pytest "counsel-test-pytest" "\
Browse and execute pytest tests.

If the value of `counsel-test-dir' is not set (e.g. nil) prompt user for the
pytest directory.

With a prefix argument ARG also force prompt user for this directory.

\(fn ARG)" t nil)

(register-definition-prefixes "counsel-test-pytest" '("counsel-test-pytest-"))

;;;***

;;;### (autoloads nil nil ("counsel-test-pkg.el" "counsel-test.el")
;;;;;;  (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; counsel-test-autoloads.el ends here
