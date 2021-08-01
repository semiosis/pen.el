;; These are helper functions
;; examplary.el uses them.

;; So might org-brain

(defun pen-preceding-text ()
  (str (buffer-substring (point) (max 1 (- (point) 1000)))))

(defun beginning-of-line-point ()
  (save-excursion
    (beginning-of-line)
    (point)))

(defun pen-preceding-text-line ()
  (cond
   (derived-mode-p 'term-mode))
  (str (buffer-substring (point) (max 1 (beginning-of-line-point)))))

(defun get-point-start-of-nth-previous-line (n)
  (save-excursion
    (eval `(expand-macro (ntimes ,n (ignore-errors (previous-line)))))
    (beginning-of-line)
    (point)))

(defun get-point-start-of-nth-next-line (n)
  (save-excursion
    (eval `(expand-macro (ntimes ,n (ignore-errors (next-line)))))
    (beginning-of-line)
    (point)))

(defun pen-surrounding-text (&optional window-line-size)
  (if (not window-line-size)
      (setq window-line-size 20))
  (let ((window-line-radius (/ window-line-size 2)))
    (str (buffer-substring
          (get-point-start-of-nth-previous-line window-line-radius)
          (get-point-start-of-nth-next-line window-line-radius)))))

(defun pen-selection-or-surrounding-context ()
  (let ((context
         (if (selected-p)
             (pen-selected-text)
           (pen-surrounding-context))))
    (pen-snc "sed -z 's/\\s\\+/ /g'" (snc "pen-c context-chars" context))))

(defun pen-surrounding-context ()
  (pen-snc "sed -z 's/\\s\\+/ /g'" (pen-surrounding-text)))

(defun pen-thing-at-point (&optional only-if-selected)
  (interactive)

  (if (and only-if-selected
           (not mark-active))
      nil
    (if (or mark-active
            iedit-mode)
        (pen-selected-text)
      (str
       (or (thing-at-point 'symbol)
           (thing-at-point 'sexp)
           (let ((s (str (thing-at-point 'char))))
             (if (string-equal s "\n")
                 ""
               s))
           "")))))

(defun pen-thing-at-point-ask (&optional prompt)
  (interactive)
  (let ((thing (sor (pen-thing-at-point))))
    (if (not thing)
        (setq thing (read-string-hist
                     (concat
                      (or (sor prompt "pen-thing-at-point-ask")
                          "")
                      ": "))))
    thing))

(defun pen-detect-language-ask ()
  (interactive)
  (let ((langs
         (-uniq-u
          (append
           ;; TODO Make it so I can feed values into prompt functions
           ;; So, for example, I can use them inside the prompt fuzzy-finder
           (let ((context (sor
                           (pen-selected-text t)
                           (pen-preceding-text))))
             (if context
                 (pf-get-language
                  context
                  :no-select-result t)))
           (list (pen-detect-language t)
                 (pen-detect-language t t))))))

    (if (pen-var-value-maybe 'pen-single-generation-b)
        (car langs)
      (fz
       langs
       nil
       nil
       "Pen From language: "
       nil nil))))

(provide 'pen-core)