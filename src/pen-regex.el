;; TODO Take all from here
;; $EMACSD/config/my-regex.el

(defalias 'pen-unregexify 'regexp-quote)

(defun str-in-buffer-or-path-p (s)
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
      (re-in-region-or-path-p r)
    (re-in-buffer-or-path-p r)))

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
      (ire-in-region-or-path-p r)
    (ire-in-buffer-or-path-p r)))

(defun ieat-in-region-or-buffer-or-path-p (s)
  (if (use-region-p)
      (ieat-in-region-or-path-p s)
    (ieat-in-buffer-or-path-p s)))

(provide 'pen-regex)