(require 'apheleia)

;; For some reason, cant ignore errors

(advice-add 'apheleia--format-after-save :around #'ignore-errors-around-advice)
(advice-add 'apheleia--make-process :around #'ignore-errors-around-advice)
(advice-add 'apheleia--write-file-silently :around #'ignore-errors-around-advice)
;; (advice-add 'apheleia-format-buffer :around #'ignore-errors-around-advice)
;; (advice-add 'apheleia--run-formatter :around #'ignore-errors-around-advice)

;; I had to be ignore-errors inside the closure
(defun apheleia--run-formatter-command
    (command buffer callback stdin formatter)
  "Run a formatter using a shell command.
COMMAND should be a list of string or symbols for the formatter that
will format the current buffer. See `apheleia--run-formatters' for a
description of COMMAND, BUFFER, CALLBACK and STDIN. FORMATTER is
the symbol of the current formatter being run, for diagnostic
purposes."
  ;; NOTE: We switch to the original buffer both to format the command
  ;; correctly and also to ensure any buffer local variables correctly
  ;; resolve for the whole formatting process (for example
  ;; `apheleia--current-process').
  (with-current-buffer buffer
    (when-let ((ret (apheleia--format-command command stdin)))
      (cl-destructuring-bind (input-fname output-fname stdin &rest command) ret
        (apheleia--make-process
         :command command
         :stdin (unless input-fname
                  stdin)
         :callback
         (lambda (stdout)
           (ignore-errors
             (when output-fname
               ;; Load output-fname contents into the stdout buffer.
               (erase-buffer)
               (insert-file-contents-literally output-fname)))

           (funcall callback stdout))
         :ensure
         (lambda ()
           (ignore-errors
             (when input-fname
               (delete-file input-fname))
             (when output-fname
               (delete-file output-fname))))
         :formatter formatter)))))

(provide 'pen-apheleia)