(defun hebrew-letters-explain (s)
  (interactive (list (pen-ask (pen-selection) "Hebrew chars: ")))
  (let ((explanation (pen-snc "hebrew-letters-explain" s)))
    (if (interactive-p)
        (tpop "vs" explanation)
      explanation)))

(provide 'pen-hebrew)
