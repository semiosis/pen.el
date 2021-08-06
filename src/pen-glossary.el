(defalias 'add-to-glossary-file-for-buffer
  (function
   (lambda
     (term &optional take-first definition)
     "C-u will allow you to add to any glossary file"
     (interactive
      (let
          ((s
            (my/thing-at-point)))
        (if
            (not
             (sor s))
            (setq s
                  (read-string-hist "add glossary term: ")))
        (list s)))
     (deactivate-mark)
     (if
         (not definition)
         (setq definition
               (pen-qa -l
                       (lm-define term t
                                  (pen-topic t))
                       -d
                       (dictionaryapi-define term)
                       -g
                       (google-define term)
                       -w
                       (my-wiki-summary term)
                       -W
                       (my-wiki-summary
                        (snc
                         (cmd "redirect-wiki-term" term)))
                       -r
                       (read-string "definition: ")
                       -m "" -n "")))
     (let
         ((cb
           (current-buffer))
          (fp
           (if
               (is-glossary-file)
               (buffer-file-name)
             (umn
              (or
               (and
                (or
                 (>=
                  (prefix-numeric-value current-prefix-arg)
                  4)
                 (not
                  (local-variable-p 'glossary-files)))
                (umn
                 (fz
                  (mnm
                   (list2str
                    (list-glossary-files)))
                  nil nil "add-to-glossary-file-for-buffer glossary: ")))
               (and
                (local-variable-p 'glossary-files)
                (if take-first
                    (car glossary-files)
                  (umn
                   (fz
                    (mnm
                     (list2str glossary-files))
                    "$HOME/glossaries/" nil "add-to-glossary-file-for-buffer glossary: "))))
               (umn
                (fz
                 (mnm
                  (list2str
                   (list "$HOME/glossaries/glossary.txt")))
                 "$HOME/glossaries/" nil "add-to-glossary-file-for-buffer glossary: ")))))))
       (with-current-buffer
           (find-file fp)
         (progn
           (if
               (save-excursion
                 (beginning-of-line)
                 (looking-at-p
                  (concat "^"
                          (unregexify term)
                          "$")))
               (progn
                 (end-of-line))
             (progn
               (end-of-buffer)
               (newline)
               (newline)
               (insert term)))
           (newline)
           (if
               (sor definition)
               (insert
                (qa -t
                    (snc "ttp"
                         (concat "    " definition))
                    -p
                    (snc "tpp"
                         (concat "    " definition))
                    -n definition))
             (insert "    ")))
         (current-buffer))))))

(provide 'pen-glossary)