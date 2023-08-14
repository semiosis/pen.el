(require 'pen-compilation)

(setq glimpse-command "alt-glimpse")

(defun pen-glimpse (pattern &optional wd path-re)
  (interactive (list (read-string-hist "ead pattern: ")
                     (read-directory-name "ead dir: ")))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (pen-sh-wgrep pattern wd)
    (progn
      (if (not wd)
          (setq wd (pen-pwd)))
      (setq wd (pen-umn wd))
      (with-current-buffer
          ;; How can I use pen-mnm but only on the file paths? -- I want to be able to filter on a column only
          (let ((globstr (if (sor path-re)
                             (concat "-p " (pen-q path-re) " ")
                           "")))
            (new-buffer-from-string
             (ignore-errors (pen-sn (concat "pen-ead -f " globstr (pen-q pattern) " | pen-mnm | cat") nil wd))
             "*wgrep*"))
        (grep-mode)))))

(provide 'pen-glimpse)
