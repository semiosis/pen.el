(defcustom ivy-height-alist nil
  "An alist to customize `ivy-height'.

It is a list of (CALLER . HEIGHT).  CALLER is a caller of
`ivy-read' and HEIGHT is the number of lines displayed."
  :type '(alist :key-type function :value-type integer))

(if (and (not (fboundp 'org-projectile:per-repo))
         (fboundp 'org-projectile-per-project))
    (defalias 'org-projectile:per-repo 'org-projectile-per-project))

(defalias 'string-to-int 'string-to-number)

(provide 'pen-compatibility)