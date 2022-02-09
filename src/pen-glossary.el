(defun pen-pretty-paragraph (s)
  ;; This should be made optional, since it may be slow
  (pen-snc "pen-pretty-paragraph" s))

(defun pen-pretty-paragraph-selected ()
  (interactive)
  ;; This should be made optional, since it may be slow
  (pen-filter-shellscript "pen-pretty-paragraph"))

(defun pen-list-glossary-files (&optional mant-only)
  (let ((glist (sor (pen-cl-sn
                     (if mant-only
                         (pen-cmd  "pen-list-glossary-files" "-mant")
                       "pen-list-glossary-files") :chomp t))))
    (if glist
        (s-lines glist))))

(defun pen-add-to-glossary-file-for-buffer (term &optional take-first definition)
  "C-u will allow you to add to any glossary file"
  (interactive (let ((s (pen-thing-at-point)))
                 (if (not (sor s))
                     (setq s (read-string-hist "add glossary term: ")))
                 (list s)))

  (deactivate-mark)
  (if (not definition)
      (setq definition
            (pen-qa
             -l (pen-lm-define term t (pen-topic t))
             -L (pen-lm-define term t)
             ;; -d (dictionaryapi-define term)
             ;; -g (google-define term)
             ;; -w (my-wiki-summary term)
             ;; -W (my-wiki-summary (pen-snc (cmd "redirect-wiki-term" term)))
             -r (read-string "definition: ")
             -m ""
             -n "")))

  (let ((cb (current-buffer))
        ;; (gfs (if (local-variable-p 'glossary-files) glossary-files))
        (fp
         (if (is-glossary-file)
             (buffer-file-name)
           (pen-umn (or
                     (and (or (>= (prefix-numeric-value current-prefix-arg) 4)
                              (not (local-variable-p 'glossary-files)))
                          (pen-umn
                           (let ((sel (fz (pen-mnm (pen-list2str (pen-list-glossary-files t)))
                                          nil nil "pen-add-to-glossary-file-for-buffer glossary: ")))
                             (if (sor sel)
                                 (f-join "/root/.pen/glossaries" (concat sel ".txt"))
                               "/root/.pen/glossaries/general.txt"))))
                     (and
                      (local-variable-p 'glossary-files)
                      (if take-first
                          (car glossary-files)
                        (pen-umn (fz (pen-mnm (pen-list2str glossary-files))
                                     nil nil "pen-add-to-glossary-file-for-buffer glossary: "))))
                     (pen-umn (fz (pen-mnm (pen-list2str (list "/root/.pen/glossaries/general.txt")))
                                  nil nil "pen-add-to-glossary-file-for-buffer glossary: ")))))))

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
            (insert
             (pen-qa
              -p (pen-snc "pen-pretty-paragraph" (concat "    " definition))
              -n definition))
          (insert "    ")))
      (current-buffer))))

(defun pen-add-to-glossary (term &optional take-first definition topic)
  "C-u will allow you to add to any glossary file"
  (interactive (let ((s (rx/chomp (pen-snc "sed -z 's/\\s\\+/ /g'" (pen-thing-at-point-ask)))))
                 (if (not (sor s))
                     (setq s (read-string-hist "glossary term to add: ")))
                 (list s)))

  (if (not topic)
      (setq topic (pen-ask (pen-topic t) "topic: ")))

  (deactivate-mark)
  (let ((NLG))
    (if (not definition)
        (progn
          (setq definition (pen-lm-define term t topic))
          (if definition
              (setq NLG t))))

    (let* ((cb (current-buffer))
           (all-glossaries-fn-mant (pen-mnm (pen-list2str (pen-list-glossary-files t))))
           (fp
            (if (pen-is-glossary-file)
                (buffer-file-name)
              (pen-umn (or
                        (and (or (>= (prefix-numeric-value current-prefix-arg) 4)
                                 (not (local-variable-p 'glossary-files)))
                             (pen-umn (fz all-glossaries-fn-mant
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
              (if (not (looking-at "^$"))
                  (newline))
              (newline)
              (insert (chomp term))))
          (newline)
          (if (sor definition)
              ;; Do not chomp the start
              (if NLG
                  (insert (ink-propertise (chomp (pen-pretty-paragraph (concat "    " definition)))))
                (insert (chomp (pen-pretty-paragraph (concat "    " definition)))))
            (insert "    ")))
        (current-buffer)))))

(provide 'pen-glossary)