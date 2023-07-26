(defun pen-modeline-name ()
  (let ((dn (pen-daemon-name)))
    (cond ((string-equal "DEFAULT" dn)
           "🖊")
          ((s-matches? "pen-" dn)
           (s-replace-regexp
            "pen-emacsd-\\([0-9]*\\)"
            "\\1"
            dn))
          (t
           "emacs"))))

(defun ascii-letter-from-int (char)
  "convert number to letter of alphabet; 1 = a, 2 = b, etc."
  (let ((i (- char 1)))
    (if (and (>= i 0) (< i 26))
        (string (+ ?a i))
      ""
      ;; (error "ascii-letter-from-int: invalid character")
      )))

(defun pen-daemons-modeline ()
  (mapconcat 'identity
             (mapcar
              'ascii-letter-from-int
              (mapcar
               'string-to-int
               (split-string 
                (e/chomp-all
                 (pen-sn-basic "pen-ls-daemons"))
                "\n")))
             ""))

(setq-default mode-line-format
              `(" "
                ,(pen-modeline-name)
                ("  "
                 mode-line-buffer-identification "   "
                 "  " mode-line-modes)
                ;; ,(pen-daemons-modeline)
                ))

(defun pen-modeline-progressbar-demo (&optional duration)
  "Displays a progressbar in the mode-line."
  (interactive (list 3))
  (let* ((mode-line-format mode-line-format)
         (max (window-width))
         (durationl duration)
         (delta (max 0 (/ (float durationl) max)))
         (message "Processing"))
    (unwind-protect
        (dotimes (i max)
          (let* ((text (format "%s %.2f%%%%" message (* 100 (/ (float i) max))))
                 (fill (ceiling (/ (max 0 (- max (length text))) (float 2))))
                 (msg (concat (make-string fill ?\s) text (make-string fill ?\s))))
            (put-text-property 0 i 'face '(:background "royalblue") msg)
            (setq mode-line-format msg)
            (force-mode-line-update)
            (sit-for delta)))
      (force-mode-line-update))))

;; (define-key mode-line-map 'mouse-movement 'tty-menu-mouse-movement)

(provide 'pen-modeline)
