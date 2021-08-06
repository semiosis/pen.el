(defalias 'pen-unregexify 'regexp-quote)

(defun ire-in-region-or-buffer-p (r)
  (if (use-region-p)
      (ire-in-region-p r)
    (ire-in-buffer-p r)))

(defun str-in-region-or-buffer-p (s)
  (if (use-region-p)
      (str-in-region-p s)
    (str-in-buffer-p s)))

(defun re-in-region-or-buffer-or-path-p (r)
  (if (use-region-p)
      (re-in-region-or-path-p r)
    (re-in-buffer-or-path-p r)))

(defun istr-in-region-or-buffer-or-path-p (s)
  (if (use-region-p)
      (istr-in-region-or-path-p s)
    (istr-in-buffer-or-path-p s)))

(defun istr-in-region-or-buffer-p (s)
  (if (use-region-p)
      (istr-in-region-p s)
    (istr-in-buffer-p s)))

(defun ire-in-region-or-buffer-or-path-p (r)
  (if (use-region-p)
      (ire-in-region-or-path-p r)
    (ire-in-buffer-or-path-p r)))

(defun ieat-in-region-or-buffer-or-path-p (s)
  (if (use-region-p)
      (ieat-in-region-or-path-p s)
    (ieat-in-buffer-or-path-p s)))

(provide 'pen-regex)