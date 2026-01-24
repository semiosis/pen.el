(defun s-hl (color s)

  )

(defun s-hlred (s)

  )

;; (insert (s-btn (dffn 1 (snc "tv" "hi")) "YO"))
(defun s-btn (f s &rest props)
  (let* ((fstr (sym2str (dffn 1 f)))
         (bsym (str2sym (concat fstr "-button"))))
    (ignore-errors
      (define-button-type bsym
        'action f
        'follow-link t
        'face 'rdrview-number-face
        'help-echo (concat "Run " fstr)
        ;; 'help-args "test"
        ))

    (with-temp-buffer
      (insert s)
      (eval
       `(make-text-button ,(point-min)
                          ,(point-max)
                          :type ',bsym
                          ;; 'refnum num
                          ,@props))
      (buffer-string))))


(provide 'pen-hl-strings)
