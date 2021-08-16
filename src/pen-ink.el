;; https://github.com/semiosis/ink.el

(defun ink-encode (text &optional engine language topic)
  (if (not engine)
      (setq engine "OpenAI GPT-3"))
  (if (not language)
      (setq language "English"))

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
    ink))

(provide 'pen-ink)