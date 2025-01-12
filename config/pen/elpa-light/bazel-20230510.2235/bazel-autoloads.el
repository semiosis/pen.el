;;; bazel-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "bazel" "bazel.el" (0 0 0 0))
;;; Generated autoloads from bazel.el

(autoload 'bazel-build-mode "bazel" "\
Major mode for editing Bazel BUILD files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx 47 (or "BUILD" "BUILD.bazel") eos) #'bazel-build-mode))

(autoload 'bazel-workspace-mode "bazel" "\
Major mode for editing Bazel WORKSPACE files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx 47 (or "WORKSPACE" "WORKSPACE.bazel" "WORKSPACE.bzlmod") eos) #'bazel-workspace-mode))

(autoload 'bazel-module-mode "bazel" "\
Major mode for editing Bazel module files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx "/MODULE.bazel" eos) #'bazel-module-mode))

(autoload 'bazel-starlark-mode "bazel" "\
Major mode for editing Bazel Starlark files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx 47 (+ nonl) ".bzl" eos) #'bazel-starlark-mode))

(autoload 'bazelrc-mode "bazel" "\
Major mode for editing .bazelrc files.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx 47 (or "bazel.bazelrc" ".bazelrc") eos) #'bazelrc-mode))

(add-to-list 'auto-mode-alist (cons (rx "/.bazelignore" eos) #'bazelignore-mode))

(autoload 'bazelignore-mode "bazel" "\
Major mode for editing .bazelignore files.

\(fn)" t nil)

(autoload 'bazeliskrc-mode "bazel" "\


\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons (rx "/.bazeliskrc" eos) #'bazeliskrc-mode))

(register-definition-prefixes "bazel" '("bazel"))

;;;***

;;;### (autoloads nil nil ("bazel-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; bazel-autoloads.el ends here
