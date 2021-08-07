(defun pen-pretty-paragraph (s)
  ;; This should be made optional, since it may be slow
  (pen-snc "pen-pretty-paragraph" s))

(defun pen-list-glossary-files ()
  (let ((glist (sor (pen-cl-sn "pen-list-glossary-files" :chomp t))))
    (if glist
        (s-lines glist))))

(defun pen-add-to-glossary (term &optional take-first definition)
  "C-u will allow you to add to any glossary file"
  (interactive (let ((s (pen-thing-at-point-ask)))
                 (if (not (sor s))
                     (setq s (read-string-hist "glossary term to add: ")))
                 (list s)))
  (deactivate-mark)
  (if (not definition)
      (setq definition (lm-define term t (pen-topic t))))

  (let* ((cb (current-buffer))
         (all-glossaries-fp (pen-mnm (pen-list2str (pen-list-glossary-files))))
         (fp
          (if (pen-is-glossary-file)
              (buffer-file-name)
            (pen-umn (or
                      (and (or (>= (prefix-numeric-value current-prefix-arg) 4)
                               (not (local-variable-p 'glossary-files)))
                           (pen-umn (fz all-glossaries-fp
                                        nil nil "glossary to add to: ")))
                      (and
                       (local-variable-p 'glossary-files)
                       (if take-first
                           (car glossary-files)
                         (pen-umn (fz (pen-mnm (pen-list2str glossary-files))
                                      "$HOME/glossaries/"
                                      nil "glossary to add to: "))))
                      (pen-umn (fz (pen-mnm (pen-list2str (list "$HOME/glossaries/glossary.txt")))
                                   "$HOME/glossaries/"
                                   nil "glossary to add to: ")))))))
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