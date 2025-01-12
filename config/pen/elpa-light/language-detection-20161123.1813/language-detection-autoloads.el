;;; language-detection-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "language-detection" "language-detection.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from language-detection.el

(autoload 'language-detection-buffer "language-detection" "\
Predict the programming language of the current buffer and output it to messages.

\(fn &optional PRINT-MESSAGE)" t nil)

(autoload 'language-detection-string "language-detection" "\
Return the predicted programming language of STRING as a symbol.

\(fn STRING)" nil nil)

(register-definition-prefixes "language-detection" '("language-detection-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; language-detection-autoloads.el ends here
