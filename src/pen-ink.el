;; https://github.com/semiosis/ink.el

;; *( is so it will work in YAML. However, it
;; still requires escaping, so now it's just to
;; differentiate from regular text properties,
;; but the differentiation serves no useful
;; purpose.

(defun ink-encode (text &optional engine language topic)
  (interactive (list
                (pen-selection)
                (read-string-hist "engine: ")
                (read-string-hist "language: ")
                (read-string-hist "topic: ")))
  (if (not engine)
      (setq engine "OpenAI GPT-3"))
  (if (not language)
      (setq language "English"))

  (let* ((ink
          (let ((buf (new-buffer-from-string text))
                (ink)
                (start 1)
                (end))
            (with-current-buffer buf
              (setq end (length text))
              (put-text-property start end 'engine engine)
              (put-text-property start end 'language language)
              (put-text-property start end 'topic topic)
              (setq ink (format "%S" (buffer-string))))
            (kill-buffer buf)
            ink))
         (ink (string-replace "#(" "*(" ink)))
    (if (interactive-p)
        (if (pen-selected-p)
            (pen-region-filter (eval `(lambda (s) ,ink)))
          (pen-etv ink))
      ink)))

(defun ink-decode (text)
  ;; Do not use (pen-selection t)
  ;; This assumes the text is visibly encoded
  (interactive (list (pen-selection)))

  (if (sor text)
      (let* ((text (if (string-match "\\*(" text)
                       (str (eval-string (string-replace "*(" "#(" text)))
                     text)))
        (if (interactive-p)
            (if (pen-selected-p)
                (pen-region-filter (eval `(lambda (s) ,text)))
              (pen-etv text))
          text))))

(provide 'pen-ink)