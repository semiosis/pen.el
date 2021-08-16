;; https://github.com/semiosis/ink.el

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

  (let ((ink
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
           ink)))
    (if (interactive-p)
        (if (pen-selected-p)
            (pen-region-filter (eval `(lambda (s) ,ink)))
          (pen-etv ink))
      (ink))))

(defun ink-decode (text &optional engine language topic)
  (interactive (list
                (pen-selection)
                (read-string-hist "engine: ")
                (read-string-hist "language: ")
                (read-string-hist "topic: ")))
  (if (not engine)
      (setq engine "OpenAI GPT-3"))
  (if (not language)
      (setq language "English"))

  (let ((ink
         (let ((buf (new-buffer-from-string text))
               (ink)
               (start 1)
               (end))
           (with-current-buffer buf
             ;; (insert text)
             (setq end (length text))
             (put-text-property start end 'engine engine)
             (put-text-property start end 'language language)
             (put-text-property start end 'topic topic)
             (setq ink (format "%S" (buffer-string))))
           (kill-buffer buf)
           ink)))
    (if (interactive-p)
        (if (pen-selected-p)
            (pen-region-filter (eval `(lambda (s) ,ink)))
          (pen-etv ink))
      (ink))))

(provide 'pen-ink)