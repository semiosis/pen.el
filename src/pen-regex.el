;; TODO Take all from here
;; $EMACSD/config/my-regex.el

(defalias 'pen-unregexify 'regexp-quote)
(defalias 'major-mode-p 'derived-mode-p)

(defun recenter-top ()
  (interactive)
  (ignore-errors
    (recenter-top-bottom scroll-margin)))

;; This is horrible
(defun pen-select-regex-at-point (pat &optional literal)
  (interactive (list (read-string-hist "re: ")))

  (deselect)

  (if pat
      (let ((ogpos (point))
            (ogpat pat))
        (if literal
            (setq p (regexp-quote pat)))

        (while (and (not (looking-at-p pat))
                    (not (bolp)))
          (backward-char 1))
        (while (and (looking-at-p pat)
                    (not (bolp)))
          (backward-char 1))
        (if (not (looking-at-p pat))
            (forward-char 1))

        (set-mark (point))

        (if literal
            (forward-char (length ogpat))
          (let ((boundedpat (setq pat (concat "\\`" pat "\\'"))))
            (while (and (not (string-match pat (buffer-substring (mark) (point))))
                        (not (eolp)))
              (forward-char 1))
            (while (and (string-match pat (buffer-substring (mark) (point)))
                        (not (eolp)))
              (forward-char 1))
            (if (not (string-match pat (buffer-substring (mark) (point))))
                (backward-char 1))))

        ;; (tv (concat (str (mark)) " " (str (point))))

        (if (and mark-active
                 (or
                  (< (mark) (point) ogpos)
                  (< ogpos (mark) (point))
                  (not (string-match pat (pen-selected-text)))))
          (progn (deactivate-mark)
                 (goto-char ogpos))))))

(defun save-region (&optional sym1 sym2)
  (interactive)
  (setq sym1 (or sym1 'm1))
  (setq sym2 (or sym2 'm2))
  (make-local-variable sym1)
  (make-local-variable sym2)
  (set sym1 (copy-marker (mark)))
  (set sym2 (copy-marker (point))))

(advice-add 'save-region :around #'ignore-errors-around-advice)

(defun restore-region (&optional sym1 sym2)
  (interactive)
  (setq sym1 (or sym1 'm1))
  (setq sym2 (or sym2 'm2))
  (set-mark (eval sym1))
  (goto-char (eval sym2)))

(advice-add 'restore-region :around #'ignore-errors-around-advice)

;; (save-excursion-and-region-reliably (replace-region (selection)))
;; These are actually incompatible
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

(defun pen-regex-at-point-p (re &optional literal)
  (if literal
      (setq re (regexp-quote re)))

  (let ((found)
        (sel))
    (save-excursion-and-region-reliably
     (pen-select-regex-at-point re)
     (setq sel (pen-selection))
     (let ((m (mark)))
       (goto-char m)
       (setq found (looking-at-p re))))
    (if found
        sel)))
(defalias 'regex-at-point 'pen-regex-at-point-p)

(defmacro pen-re-sensitive (&rest body)
  `(let ((case-fold-search nil))
     ,@body))
(defmacro pen-re-insensitive (&rest body)
  `(let ((case-fold-search t))
     ,@body))

(defun pen-string-match-literal (literal-pattern string &optional start)
  (if (stringp string)
      (pen-re-sensitive
       (string-match (regexp-quote literal-pattern) string start))))
(defalias 'str-match-p 'pen-string-match-literal)

(defun pen-string-match-literal-insensitive (pattern string &optional start)
  (if (stringp string)
      (pen-re-insensitive
       (string-match (regexp-quote pattern) string start))))
(defalias 'istring-match-literal 'pen-string-match-literal-insensitive)
(defalias 'istr-match-p 'pen-string-match-literal-insensitive)

(defalias 're-match-p 'string-match)

(defun pen-string-match-insensitive (pattern string &optional start)
  (if (stringp string)
      (pen-re-insensitive
       (string-match pattern string start))))
(defalias 'ire-match-p 'pen-string-match-insensitive)

(defun pen-string-in-region-p (s)
  (if (use-region-p)
      (let ((bs (pen-selection)))
        (if (stringp bs)
            (pen-re-sensitive
             (pen-string-match-literal s bs))))))
(defalias 'str-in-region-p 'pen-string-in-region-p)

(defun pen-string-in-buffer-p (s)
  (let ((bs (buffer-string)))
    (if (stringp bs)
        (pen-re-sensitive
         (pen-string-match-literal s bs)))))
(defalias 'str-in-buffer-p 'pen-string-in-buffer-p)

(defun pen-istring-in-region-p (s)
  (istring-match-literal s (sor (pen-selection) "")))
(defalias 'istr-in-region-p 'pen-istring-in-region-p)

(defun pen-istring-in-buffer-p (s)
  (istring-match-literal s (buffer-string)))
(defalias 'istr-in-buffer-p 'pen-istring-in-buffer-p)

(defun pen-istr-in-region-or-path-p (s)
  (let ((p (get-path-nocreate))
        (rs (sor (pen-selection) "")))
    (if (and (stringp s)
             (stringp rs))
        (or (istring-match-literal s rs)
            (istring-match-literal s p)))))

(defun pen-str-in-buffer-or-path-p (s)
  (let ((p (get-path-nocreate))
        (bs (buffer-string)))
    (if (and (stringp s)
             (stringp bs))
        (or (pen-string-match-literal s bs)
            (pen-string-match-literal s p)))))

(defun pen-istr-in-buffer-or-path-p (s)
  (let ((p (get-path-nocreate))
        (bs (buffer-string)))
    (if (and (stringp s)
             (stringp bs))
        (or (istring-match-literal s bs)
            (istring-match-literal s p)))))

(defun pen-re-in-buffer-p (s)
  (if (stringp s)
      (pen-re-sensitive
       (string-match s (buffer-string)))))

(defun pen-ire-in-region-p (s)
  (if (use-region-p)
      (let ((bs (pen-selection)))
        (if (stringp bs)
            (pen-string-match-insensitive s bs)))))

(defun pen-ire-in-buffer-p (s)
  (let ((bs (buffer-string)))
    (if (stringp bs)
        (pen-string-match-insensitive s bs))))

(defun pen-re-in-region-or-path-p (s)
  (let ((p (get-path-nocreate))
        (rs (sor (pen-selection) "")))
    (pen-re-sensitive
     (or (and (stringp s) (stringp rs) (string-match s rs))
         (and (stringp s) (stringp p) (string-match s p))))))

(defun pen-re-in-buffer-or-path-p (s)
  (let ((p (get-path-nocreate))
        (bs (buffer-string)))
    (pen-re-sensitive
     (or (and (stringp s) (stringp bs) (string-match s bs))
         (and (stringp s) (stringp p) (string-match s p))))))

(defun pen-ire-in-region-or-path-p (s)
  (let ((p (get-path-nocreate))
        (rs (sor (pen-selection) "")))
    (pen-re-insensitive
     (or (and (stringp s) (stringp rs) (string-match s rs))
         (and (stringp s) (stringp p) (string-match s p))))))

(defun pen-ire-in-buffer-or-path-p (s)
  (let ((p (get-path-nocreate))
        (bs (buffer-string)))
    (pen-re-insensitive
     (or (and (stringp s) (stringp bs) (string-match s bs))
         (and (stringp s) (stringp p) (string-match s p))))))

;; (pen-re-insensitive (string-match "\\bamazon\\b" (buffer-string)))
(defun pen-ieat-in-region-or-path-p (s)
  (pen-ire-in-region-or-path-p (concat "\\b" s "\\b")))
(defalias 'pen-ieat-in-region-or-buffer-p 'pen-ieat-in-region-or-path-p)
(defun pen-eat-in-region-or-path-p (s)
  (pen-re-in-region-or-path-p (concat "\\b" s "\\b")))

(defun pen-ieat-in-buffer-or-path-p (s)
  (pen-ire-in-buffer-or-path-p (concat "\\b" s "\\b")))
(defun pen-eat-in-buffer-or-path-p (s)
  (pen-re-in-buffer-or-path-p (concat "\\b" s "\\b")))

(defun pen-regex-match-string-1 (pat s)
  "Get first match from substring"
  (save-match-data
    (and (string-match pat s)
         (or (match-string-no-properties 1 s)
             (match-string-no-properties 0 s)))))
(defalias 'regex-match-string 'pen-regex-match-string-1)
(defalias 's-substring 'regex-match-string-1)

(defun pen-re-seq (regexp string)
  "Get a list of all regexp matches in a string"
  (save-match-data
    (let ((pos 0)
          matches)
      (while (string-match regexp string pos)
        (push (match-string-no-properties 0 string) matches)
        (setq pos (match-end 0)))
      matches)))
(defalias 'regex-matches 'pen-re-seq)

(defun pen-str-p (s)
  (let ((p (get-path-nocreate))
        (bs (buffer-string)))
    (if (and (stringp s)
             (stringp bs))
        (or (string-match-literal s bs)
            (string-match-literal s p)))))

(defun pen-str-p (s)
  (if (use-region-p)
      (str-in-region-p s)
    (str-in-buffer-p s)))

(defun pen-re-p (r)
  (if (use-region-p)
      (pen-re-in-region-or-path-p r)
    (pen-re-in-buffer-or-path-p r)))

(defun pen-istr-p (s)
  (if (use-region-p)
      (istr-in-region-or-path-p s)
    (istr-in-buffer-or-path-p s)))

(defun pen-istr-p (s)
  (if (use-region-p)
      (istr-in-region-p s)
    (istr-in-buffer-p s)))

(defun pen-ire-p (r)
  (if (use-region-p)
      (pen-ire-in-region-or-path-p r)
    (pen-ire-in-buffer-or-path-p r)))

(defun pen-ieat-in-region-or-buffer-or-path-p (s)
  (if (use-region-p)
      (pen-ieat-in-region-or-path-p s)
    (pen-ieat-in-buffer-or-path-p s)))

(provide 'pen-regex)
