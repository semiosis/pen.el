(defun pen-pretty-paragraph (s)
  ;; This should be made optional, since it may be slow
  (snc "pen-pretty-paragraph" s))

(defun pen-add-to-glossary-file-for-buffer (term &optional take-first definition)
  "C-u will allow you to add to any glossary file"
  (interactive (let ((s (pen-thing-at-point-ask)))
                 (if (not (sor s))
                     (setq s (read-string-hist "add glossary term: ")))
                 (list s)))
  (deactivate-mark)
  (if (not definition)
      (setq definition (lm-define term t (pen-topic t))))

  (let ((cb (current-buffer))
        (fp
         (if (pen-is-glossary-file)
             (buffer-file-name)
           (pen-umn (or
                     (and (or (>= (prefix-numeric-value current-prefix-arg) 4)
                              (not (local-variable-p 'glossary-files)))
                          (pen-umn (fz (pen-mnm (pen-list2str (list-glossary-files)))
                                       nil nil "add-to-glossary-file-for-buffer glossary: ")))
                     (and
                      (local-variable-p 'glossary-files)
                      (if take-first
                          (car glossary-files)
                        (pen-umn (fz (pen-mnm (pen-list2str glossary-files))
                                     "$HOME/glossaries/"
                                     nil "add-to-glossary-file-for-buffer glossary: "))))
                     (pen-umn (fz (pen-mnm (pen-list2str (list "$HOME/glossaries/glossary.txt")))
                                  "$HOME/glossaries/"
                                  nil "add-to-glossary-file-for-buffer glossary: ")))))))
    (with-current-buffer
        (find-file fp)
      (progn
        (if (save-excursion
              (beginning-of-line)
              (looking-at-p (concat "^" (pen-unregexify term) "$")))
            (progn
              (end-of-line))
          (progn
            (end-of-buffer)
            (newline)
            (newline)
            (insert term)))
        (newline)
        (if (sor definition)
            (insert (pen-pretty-paragraph (concat "    " definition)))
          (insert "    ")))
      (current-buffer))))

(provide 'pen-glossary)