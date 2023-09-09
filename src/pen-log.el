;; Remember:
;; profiler-start
;; profiler-stop
;; profiler-report


;; This is for ELK logs, etc.
(use-package logview :defer t)


;; This is for my own logging - profiling
(defmacro penlog (&rest body)
  ""
  (let ((s (concat "penlog: " (pp-to-string body))))
    `(progn
       (message "%s" ,s)
       ,@body)))


;; (si "tabulated-list-format column-size" (max 10 (min 30 (length e))))

(defun si (category input &rest args)
  ;; input may also be nil

  ;; (ignore-errors (shut-up (pen-sn (concat "si +" category " " (cmdl args)) (str input))))
  (ignore-errors (pen-snc (concat "si +" category " " (cmdl args)) (pp-to-string input)))
  input)

(defun uncmd (s)
  (s-lines (pen-snc (concat "pl " s))))

(defun pen-record (category-and-args-string &optional input)
  (let* ((λ (uncmd category-and-args-string))
         (cat (car l) ))
    (si cat input (rest l))))

;; Stream logger. It records timestamps as they come in
;; This isn't properly hooked into emacs yet
;; (defalias 'pen-record 'si)



;; TODO Make a function for logging all functions defined within a file



;; (defun penlog-around-advice (proc &rest args)
;;   (message (concat "penlog fun: " (str proc)))
;;   (message (concat "penlog args: " (str args)))
;;   (let ((res (apply proc args)))
;;     res))

(defset funs-to-trace '(pen-glossary-list-relevant-glossaries
                        pen-glossary-add-relevant-glossaries
                        pen-generate-glossary-buttons-manually
                        pen-generate-glossary-buttons-over-region
                        pen-generate-glossary-buttons-over-buffer
                        pen-make-buttons-for-glossary-terms))



;; This is useful, but unfortunately, it does not show in real-time
;; what functions are being run.
;; Perhaps I need a profiler.
(defun pen-trace-trace-list ()
  (interactive)
  (cl-loop for f in funs-to-trace do
           (trace-function f)))
(defun pen-untrace-trace-list ()
  (interactive)
  (cl-loop for f in funs-to-trace do
           (untrace-function f)))
(defvar pen-trace-modeline-indicator " MT"
  "call (pen-trace-install-mode) again if this is changed")
(defvar pen-trace-mode nil)
;; (make-variable-buffer-local 'pen-trace-mode)
;; (put 'pen-trace-mode 'permanent-local t)
(defun pen-trace-mode (&optional arg)
  ""
  (interactive "P")
  (setq pen-trace-mode
        (if (null arg) (not pen-trace-mode)
          (> (prefix-numeric-value arg) 0)))

  (if pen-trace-mode
      (pen-trace-trace-list)
    (pen-untrace-trace-list))
  (force-mode-line-update))
(provide 'pen-trace-mode)



(never
 (advice-add 'pen-glossary-list-relevant-glossaries :around #'penlog-around-advice)
 (advice-add 'pen-glossary-add-relevant-glossaries :around #'penlog-around-advice)
 (advice-add 'pen-generate-glossary-buttons-manually :around #'penlog-around-advice)
 (advice-add 'pen-generate-glossary-buttons-over-region :around #'penlog-around-advice)
 (advice-add 'pen-generate-glossary-buttons-over-buffer :around #'penlog-around-advice)
 (advice-add 'pen-make-buttons-for-glossary-terms :around #'penlog-around-advice)

 (advice-remove 'pen-glossary-list-relevant-glossaries #'penlog-around-advice)
 (advice-remove 'pen-glossary-add-relevant-glossaries #'penlog-around-advice)
 (advice-remove 'pen-generate-glossary-buttons-manually #'penlog-around-advice)
 (advice-remove 'pen-generate-glossary-buttons-over-region #'penlog-around-advice)
 (advice-remove 'pen-generate-glossary-buttons-over-buffer #'penlog-around-advice)
 (advice-remove 'pen-make-buttons-for-glossary-terms #'penlog-around-advice))

(provide 'pen-log)
