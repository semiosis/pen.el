;; This system is basically the way I structure things in the future
;; I must start creating and get very good at emacs lisp.

(defun pen-rpl-at-line-p (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output))
         (n (length matches)))
    (and (not (string-empty-p output)) (> n 0))))

(defun pen-rpl-at-line (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (thing-at-point 'line t))))
         (matches (pen-str2list output)))
    matches))

(defun pen-string-at-point (&optional p)
  (if (not p) (setq p (point)))
  (str (buffer-substring p (save-excursion (goto-char p) (line-end-position)))))

(defun pen-rpl-at-point (rpl)
  (let* ((output (chomp (pen-sn (concat "rosie grep -o subs " (pen-q rpl)) (pen-string-at-point))))
         (matches (and (not (string-empty-p output)) (pen-str2list output))))
    matches))

(defun pen-rpl-at-point-p (rpl)
  (< 0 (length (pen-rpl-at-point rpl))))

(df pen-copy-ip-here (xc (first (pen-rpl-at-point "net.ipv4"))))
(df pen-copy-email-here (xc (first (pen-rpl-at-line "net.email"))))

(defun pen-buffer-cron-lines ()
  (sor (pen-snc "pen-scrape \"((?:[0-9,/-]+|\\\\*)\\\\s+){4}(?:[0-9]+|\\\\*)\"" (buffer-string))))

(progn
  (defset pen-context-tuples
    `((((major-mode-p 'emacs-lisp-mode)
        (pen-rpl-at-point-p "net.ipv4"))
       (pen-copy-ip-here))
      (((or (major-mode-p 'org-mode)
            (major-mode-p 'text-mode)
            (major-mode-p 'markdown-mode))
        (pen-rpl-at-line-p "net.email"))
       (pen-copy-email-here))))
  (setq context-preds '())
  (setq context-pred-funcs '())
  (setq context-tuples-compiled '()))

(defun pen-hash-expression (expr)
  (sha1 (str expr)))

(defun pen-func-for-expression (nameprefix expr &optional update slugify-input)
  (let* ((funcsym (intern (concat nameprefix "-" (if slugify-input
                                                      (slugify slugify-input)
                                                   (pen-hash-expression expr))))))
    (if (and (not update) (fboundp funcsym))
        funcsym
      (eval `(progn
               (defun ,funcsym ()
                 (ignore-errors (memoize-by-buffer-contents ',funcsym))
                 ,expr))))))

(defalias 'pen-context-pen-func-for-expression
  (apply-partially 'pen-func-for-expression "pen-contextp"))

(defun pen-compile-context-tuple (context-tuple)
  (let ((pred-funcs (mapcar 'pen-context-pen-func-for-expression (car context-tuple))))
    ;; A list of functions and a list of calls
    (list pred-funcs (-drop 1 context-tuple))))

(defun pen-build-context-functions ()
  (interactive)
  (setq context-preds (-distinct (flatten-once (cl-loop for tup in pen-context-tuples collect (car tup)))))

  ;; Go through and make functions first -- a little unnecessary
  (setq context-pred-funcs (cl-loop for pred in context-preds collect (pen-context-pen-func-for-expression pred)))

  (setq context-tuples-compiled (cl-loop for tup in pen-context-tuples collect (pen-compile-context-tuple tup))))

(pen-build-context-functions)

(defun pen-suggest-funcs-unmemoize ()
  (interactive)
  (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-restore f))))

(defun pen-suggest-funcs-collect ()
  (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-orig f)))

  (let ((suggestions
         (cl-loop for tup in context-tuples-compiled
                  collect
                  (if (eval `(and ,@(mapcar 'list (car tup))))
                      (second tup)
                    '()))))

    (cl-loop for f in context-pred-funcs do (ignore-errors (memoize-restore f)))
    ;; (etv (pps suggestions))
    (remove nil (-distinct (-flatten suggestions)))))

(defun pen-suggest-funcs ()
  (interactive)
  (let* ((fz-input (pen-suggest-funcs-collect))
         (sel (if fz-input
                  (fz fz-input nil nil "suggest-funcs: "))))
    (if sel
        (let ((selsym (intern sel)))
          (if (and (function-p selsym) (commandp selsym))
              (call-interactively selsym)
            (call-function selsym))))))

(defun edit-pen-context ()
  (interactive)
  (pen-find-thing 'pen-context-tuples))

(define-key pen-map (kbd "H-TAB t") 'pen-suggest-funcs)
(define-key pen-map (kbd "<H-tab> t") 'pen-suggest-funcs)
(define-key pen-map (kbd "H-TAB T") 'edit-pen-context)
(define-key pen-map (kbd "<H-tab> T") 'edit-pen-context)

(provide 'pen-context)