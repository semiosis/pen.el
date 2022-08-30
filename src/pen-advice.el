(require 'pen-pcre)

(advice-add 'message-no-echo :around #'ignore-errors-around-advice)

(defun ignore-errors-passthrough-around-advice (proc arg)
  (try
   (let ((res (apply proc (list arg))))
     res)
   arg))

(defun wiki-summary-after-advice (&rest args)
  (toggle-read-only)
  (pen-region-pipe "ttp")
  (toggle-read-only))

(advice-add 'wiki-summary/format-summary-in-buffer :after 'wiki-summary-after-advice)

(defun compile-goto-error-after-advice (&rest args)
  (delete-other-windows))
(advice-add 'compile-goto-error :after 'compile-goto-error-after-advice)

(defun advice-unadvice (sym)
  "Remove all advices from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))
(defalias 'advice-remove-all-from 'advice-unadvice)

(defun unique-buffer-generic-after-advice (&rest args)
  "Give the buffer a unique name"
  (ignore-errors (let* ((hash (short-hash (str (time-to-seconds))))
                        (new-buffer-name (pcre-replace-string "(\\*?)$" (concat "-" hash "\\1") (buffer-name))))
                   (rename-buffer new-buffer-name))))

(defun perl-repl-after-advice (&rest args)
  "Give the buffer a unique name"
  (with-current-buffer "*Perl-REPL*" (eval `(unique-buffer-generic-after-advice ,@args))
                       t))

(advice-add 'perl-repl :after 'perl-repl-after-advice)

(advice-add 'dictionary-search :after 'unique-buffer-generic-after-advice)

(advice-add 'calculator :after 'unique-buffer-generic-after-advice)

(advice-add 'term :after 'unique-buffer-generic-after-advice)

(defun howdoyou-after-advice (&rest args)
  "Give the buffer a unique name"
  (ignore-errors (with-current-buffer "*How Do You*" (rename-buffer (concat "*How Do You-" (short-hash (str (time-to-seconds))) "*"))) t))

(advice-add 'howdoyou--print-answer :after 'howdoyou-after-advice)

(ad-get-advice-info 'wiki-summary)

(defun helm--advice-push-mark (&optional location nomsg activate)
  (unless (null (mark t))
    (let ((marker (copy-marker (mark-marker))))
      (setq mark-ring (cons marker (delete marker mark-ring))))
    (when (> (length mark-ring) mark-ring-max)
      ;; Move marker to nowhere.
      (set-marker (car (nthcdr mark-ring-max mark-ring)) nil)
      (setcdr (nthcdr (1- mark-ring-max) mark-ring) nil)))
  (set-marker (mark-marker) (or location (point)) (current-buffer))
  ;; Now push the mark on the global mark ring.
  (setq global-mark-ring (cons (copy-marker (mark-marker))
                               ;; Avoid having multiple entries
                               ;; for same buffer in `global-mark-ring'.
                               (cl-loop with mb = (current-buffer)
                                        for m in global-mark-ring
                                        for nmb = (marker-buffer m)
                                        unless (eq mb nmb)
                                        collect m)))
  (when (> (length global-mark-ring) global-mark-ring-max)
    (set-marker (car (nthcdr global-mark-ring-max global-mark-ring)) nil)
    (setcdr (nthcdr (1- global-mark-ring-max) global-mark-ring) nil))
  (when (or activate (not transient-mark-mode))
    (set-mark (mark t)))
  nil)

(defun wrap2 (orig-fun &rest args)
  (message "shr-copy-url called with args %S" args)
  (let ((res (apply orig-fun args)))
    (message "shr-copy-url returned %S" res)
    res))
(advice-add 'shr-copy-url :around #'wrap2)

(defun pen-revert-kill-buffer-and-window ()
  (interactive)
  (force-revert-buffer)

  (pen-kill-buffer-and-window))

(defun pen-log-args (f &rest args)
         (message "advice for %s: %s" f args)
         (apply f args))

(defmacro run-with-advice-disabled (&rest body)
  `(progn (ad-deactivate-all)
          ,@body
          (ad-activate-all)
          ))

(defalias 'disable-advice-temporarily 'run-with-advice-disabled)
(defalias 'progn-noadvice 'run-with-advice-disabled)

(defun lispy-goto-symbol-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    res))
(advice-add 'lispy-goto-symbol :around #'lispy-goto-symbol-around-advice)

(require 'org)
(defun org-kill-line-around-advice (proc &rest args)
  (cl-letf (((symbol-function 'kill-visual-line) #'kill-line))
    (let* ((res (apply proc args))
           res))))
(advice-add 'org-kill-line :around #'org-kill-line-around-advice)

(defun helm-etags-select-around-advice (proc &rest args)
  (cl-letf (((symbol-function 'thing-at-point) (lambda (&rest body) "")))
    (let ((res (apply proc args)))
      res)))

(advice-add 'helm-etags-select :around #'helm-etags-select-around-advice)

(defun eval-last-sexp-around-advice (proc &rest args)
  (if (derived-mode-p 'emacs-lisp-mode)
      (let ((res (apply proc args)))
        (message "eval-last-sexp returned %S" res)
        res)
    (error "Not emacs lisp.")))
(advice-add 'eval-last-sexp :around #'eval-last-sexp-around-advice)

(defun advise-to-shut-up (proc &rest args)
  (shut-up
    (let ((res (apply proc args)))
      res)))
(defalias 'shut-up-around-advice 'advise-to-shut-up)

(defun advise-to-ignore-errors (proc &rest args)
  (ignore-errors
    (let ((res (apply proc args)))
      res)))

(defun advise-to-save-excursion (proc &rest args)
  (save-excursion
    (let ((res (apply proc args)))
      res)))

(defmacro save-excursion-and-region-reliably (&rest body)
  `(save-excursion
     (save-region)
     (let* ((ma mark-active)
            (deactivate-mark nil)
            (res (progn ,@body)))
       (restore-region)
       (if (and (not ma)
                mark-active)
           (deactivate-mark t))
       res)))

(defmacro save-excursion-reliably (&rest body)
  `(let* ((p (point))
          (res (progn ,@body)))
     (goto-char p)
     res))

(defun advise-to-save-region (proc &rest args)
  (if mark-active
      (save-excursion
        (save-region)
        (let* ((deactivate-mark nil)
               (res (ignore-errors (apply proc args))))
          (restore-region)
          res))
    (let ((res (apply proc args)))
      res)))

(advice-add 'find-file-hook--open-junk-file :around #'advise-to-ignore-errors)

(advice-add 'flyspell-check-word-p :around #'advise-to-ignore-errors)

(advice-add 'orderless-all-completions :around #'advise-to-ignore-errors)
(advice-add 'all-completions :around #'advise-to-ignore-errors)

(defun advise-to-yes (proc &rest args)
  (cl-letf (((symbol-function 'yes-or-no-p) #'true))
    (let ((res (apply proc args)))
      res)))
(advice-add 'yas-reload-all :around #'advise-to-yes)

(advice-add 'kill-buffer :around #'advise-to-yes)

(defun cgify-around-advice (proc &rest args)
  (let ((inhibit-quit t))
    (unless (with-local-quit
              (let ((res (apply proc args)))
                res)
              t)
      (progn
        (message "%s" (concat "you hit C-g on " (symbol-name proc)))
        (setq quit-flag nil)))))

(provide 'pen-advice)
