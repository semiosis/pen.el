;;; flycheck-dmd-dub-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "flycheck-dmd-dub" "flycheck-dmd-dub.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from flycheck-dmd-dub.el

(autoload 'flycheck-dmd-dub-set-variables "flycheck-dmd-dub" "\
Set all flycheck-dmd variables.
It also outputs the values of `import-paths' and `string-import-paths'
to `fldd--cache-file' to reuse the result of dub describe." t nil)

(autoload 'fldd-run "flycheck-dmd-dub" "\
Set all flycheck-dmd variables.
It also outputs the values of `import-paths' and `string-import-paths'
to `fldd--cache-file' to reuse the result of dub describe." t nil)

(register-definition-prefixes "flycheck-dmd-dub" '("fldd-" "flycheck-dmd-dub-add-version"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; flycheck-dmd-dub-autoloads.el ends here
