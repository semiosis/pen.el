(defun pen-list-faces (&optional regexp)
  "List all faces, using the same sample text in each.
The sample text is a string that comes from the variable
`list-faces-sample-text'.

If REGEXP is non-nil, list only those faces with names matching
this regular expression.  When called interactively with a prefix
argument, prompt for a regular expression using `read-regexp'."
  (interactive (list (and current-prefix-arg
                          (read-regexp "List faces matching regexp"))))
  (let ((all-faces (zerop (length regexp)))
        (frame (selected-frame))
        (max-length 0)
        faces line-format
        disp-frame window face-name)
    ;; We filter and take the max length in one pass
    (delq nil
          (mapcar (lambda (f)
                    (let ((s (symbol-name f)))
                      (when (or all-faces (string-match-p regexp s))
                        (setq max-length (max (length s) max-length))
                        f)))
                  (sort (face-list) #'string-lessp)))))

;; https://stackoverflow.com/questions/884498/how-do-i-intercept-ctrl-g-in-emacs
(defun pen-customize-face (face)
  (interactive
   (let ((inhibit-quit t)
         (hlm (ignore-errors global-hl-line-mode)))
     (if hlm
         (ignore-errors
           (global-hl-line-mode -1)))

     (let ((f))
       ;; with-local-quit always returns nil
       (unless (with-local-quit
                 (setq f (str-or (fz (pen-list-faces)
                                     (if (and
                                          (face-at-point)
                                          (yes-or-no-p "Face at point?"))
                                         (symbol-name
                                          (face-at-point)))
                                     nil
                                     "face: ")
                                 nil)))
         (progn
           (setq quit-flag nil)))
       (if hlm
           (ignore-errors (global-hl-line-mode t)))
       (list f))))
  (if face
      (customize-face (intern face))))

(define-key pen-map (kbd "M-l M-q M-f") 'pen-customize-face)

(provide 'pen-faces)