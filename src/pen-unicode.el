(defun unicode-get-hex (char)
  (interactive (list (or (sor (pen-selection))
                         (clojure-char-at-point))))
  (if char
      (xc (concat "0x" (snc (cmd "unicode-get-hex" (char-to-string (first (string-to-list char)))))))))

(defalias 'unicode-char-to-hex 'unicode-get-hex)


(provide 'pen-unicode)
