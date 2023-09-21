(defun maori-dictionary (phrase)
  (interactive (list (pen-ask (pen-thing-at-point))))

  (setq phrase (or phrase (pen-thing-at-point)))

  ;; (new-buffer-from-string )
  (let ((b (generate-new-buffer "*maori-definition*")))
    (with-current-buffer b
      (insert (snc (cmd "maori-lookup-word" phrase)))
      (beginning-of-buffer))
    (display-buffer b '(pop-to-buffer . nil))))

(provide 'pen-maori)
