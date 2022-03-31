(require 'apheleia)

;; For some reason, cant ignore errors

(advice-add 'apheleia--format-after-save :around #'ignore-errors-around-advice)
(advice-add 'apheleia--make-process :around #'ignore-errors-around-advice)
(advice-add 'apheleia--write-file-silently :around #'ignore-errors-around-advice)
;; (advice-add 'apheleia-format-buffer :around #'ignore-errors-around-advice)
;; (advice-add 'apheleia--run-formatter :around #'ignore-errors-around-advice)

;; I had to be ignore-errors inside the closure
(defun apheleia--run-formatter (command callback)
  "Run a code formatter on the current buffer.
The formatter is specified by COMMAND, a list of strings or
symbols (see `apheleia-format-buffer'). Invoke CALLBACK with one
argument, a buffer containing the output of the formatter.

If COMMAND uses the symbol `file' and the current buffer is
modified from what is written to disk, then don't do anything."
  (cl-block nil
    (let ((input-fname nil)
          (output-fname nil)
          (npx nil))
      (when (memq 'npx command)
        (setq npx t)
        (setq command (remq 'npx command)))
      (unless (stringp (car command))
        (error "Command cannot start with %S" (car command)))
      (when npx
        (when-let ((project-dir
                    (locate-dominating-file
                     default-directory "node_modules")))
          (let ((binary
                 (expand-file-name
                  (car command)
                  (expand-file-name
                   ".bin"
                   (expand-file-name
                    "node_modules"
                    project-dir)))))
            (when (file-executable-p binary)
              (setcar command binary)))))
      (when (or (memq 'file command) (memq 'filepath command))
        (setq command (mapcar (lambda (arg)
                                (if (memq arg '(file filepath))
                                    (prog1 buffer-file-name
                                      (when (buffer-modified-p)
                                        (cl-return)))
                                  arg))
                              command)))
      (when (memq 'input command)
        (let ((input-fname (make-temp-file
                            "apheleia" nil
                            (and buffer-file-name
                                 (file-name-extension
                                  buffer-file-name 'period)))))
          (apheleia--write-region-silently nil nil input-fname)
          (setq command (mapcar (lambda (arg)
                                  (if (eq arg 'input)
                                      input-fname
                                    arg))
                                command))))
      (when (memq 'output command)
        (setq output-fname (make-temp-file "apheleia"))
        (setq command (mapcar (lambda (arg)
                                (if (eq arg 'output)
                                    output-fname
                                  arg))
                              command)))
      (apheleia--make-process
       :command command
       :stdin (unless input-fname
                (current-buffer))
       :callback (lambda (stdout)
                   (ignore-errors
                     (when output-fname
                       (erase-buffer)
                       (insert-file-contents-literally output-fname))
                     (funcall callback stdout)))))))

(provide 'pen-apheleia)