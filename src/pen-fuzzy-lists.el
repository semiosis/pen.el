(defun fz-insert-function ()
  "Insert a function from my favorite functions."
  (interactive)
  (insert
   (concat "(" (fz-namespaces-func) ")"))
  (backward-char)
  (tsl " "))

(defun list-namespaces ()
  (interactive)
  (fz _namespaces nil nil "ns:" t))

(defun fz-namespaces-func ()
  (interactive)
  (fz (intern (fz _namespaces nil nil "ns:" t)) nil nil "ns/func:" t))

(defvar list-of-thing-lookups
  '(wiki-summary))

(defvar list-of-fuzzy-search-engines
  '(helm-hoogle helm-google))

(defun go-to-glossary ()
  "Go to one of the glossaries in my notes"
  (interactive)
  (let ((fp (pen-umn (fz (pen-mnm ;; (b find $HOME/notes/ws/glossaries -type f -o -type l)
                      (b find $MYGIT/mullikine/glossaries -type f -o -type l))
                     nil
                     nil
                     "go-to-glossary: "))))
    (find-file fp)))

(defun go-to-todo-list ()
  (interactive)
  (let ((fp (pen-umn (fz (mnm
                      (b find $NOTES -type f -name todo.org))
                     nil
                     nil
                     "go-to-todo-list: "))))
    (find-file fp)))

(defun go-to-remember-file ()
  (interactive)
  (let ((fp (pen-umn (fz (mnm
                      (b find $NOTES -type f -name remember.org))
                     nil
                     nil
                     "go-to-remember-file: "))))
    (find-file fp)))


(defun add-to-fuzzy-list-txt (&optional sym lst)
  "Adds the symbol under cursor to the fuzzy list selected"
  (interactive (list
                (read-string-hist "add-to-fuzzy-list-txt: "
                                  (if mark-active
                                      (pen-selected-text)
                                    (esed "^\\*" "" (or (str (thing-at-point 'sexp))
                                                        ""))))
                (cond
                 ((derived-mode-p 'prog-mode)
                  (concat "functions/" (detect-language))
                  )
                 (t (fz
                     (pen-snc (concat (pen-cmd "find" "$HOME/notes/ws/lists" "-type" "f") "| path-lasttwo | sed \"s/\\\\..*//\""))
                     nil
                     nil
                     "add-to-fuzzy-list: ")))))

  (let ((fp (pen-umn (concat "$HOME/notes/ws/lists/" lst ".txt"))))
    (if (and sym lst)
        (pen-snc (pen-cmd "append-uniq" fp) sym))

    (e fp)))

(defun add-to-fuzzy-list-org (&optional sym-or-text lst)
  "Adds the symbol under cursor to the fuzzy list selected"
  (interactive (list
                (if mark-active
                    (pen-selected-text)
                  (esed "^\\*" "" (or (str (thing-at-point 'sexp))
                                      "")))
                (cond
                 ((derived-mode-p 'prog-mode)
                  (concat "functions/" (detect-language))
                  )
                 (t (fz
                     (pen-snc (concat (pen-cmd "find" "$HOME/notes/ws/lists" "-type" "f" "-name" "*.org") "| path-lasttwo | sed \"s/\\\\..*//\""))
                     nil
                     nil
                     "add-to-fuzzy-list: ")))))

  (if (not lst)
      (setq lst
            (fz
             ;; (b find $HOME/notes/ws/lists -type f | path-lasttwo | sed "s/\\..*//")
             (pen-snc (concat (pen-cmd "find" "$HOME/notes/ws/lists" "-type" "f" "-name" "*.org") "| path-lasttwo | sed \"s/\\\\..*//\""))
             nil
             nil
             "add-to-fuzzy-list: ")))

  (let* ((heading-or-content (qa -h "add as heading"
                                 -c "add as content"))
         (fp (pen-umn (concat "$HOME/notes/ws/lists/" lst ".org")))
         (hn
          (cond
           ((string-equal heading-or-content "add as heading") (concat "=" sym-or-text "="))
           ((string-equal heading-or-content "add as content") "")
           (t "")))
         (content
          (cond
           ((string-equal heading-or-content "add as heading") "")
           ((string-equal heading-or-content "add as content") sym-or-text)
           (t ""))))
    (with-current-buffer (e fp)
      (if (and (sor (str sym-or-text))
               lst)
          (if (and
               (sor hn)
               (-contains? (pen-org-list-top-level-headings) hn))
              (pen-org-select-heading hn)
            (progn
              (beginning-of-buffer)
              (newline)
              (backward-char)
              (insert (concat "* " hn))
              (if (sor content)
                  (insert (concat "\n" (pen-snc (pen-cmd "org-template-gen" "text") content))))
              (save-buffer)))))))

(defun add-to-fuzzy-list-org-enter (&optional sym lst)
  "Adds the symbol under cursor to the fuzzy list selected"
  (interactive (list
                (read-string-hist "add-to-fuzzy-list-txt: "
                                  (if mark-active
                                      (pen-selected-text)
                                    (esed "^\\*" "" (or (str (thing-at-point 'sexp))
                                                        ""))))
                (cond
                 ((derived-mode-p 'prog-mode)
                  (concat "functions/" (detect-language))
                  )
                 (t (fz
                     (pen-snc (concat (pen-cmd "find" "$HOME/notes/ws/lists" "-type" "f" "-name" "*.org") "| path-lasttwo | sed \"s/\\\\..*//\""))
                     nil
                     nil
                     "add-to-fuzzy-list: ")))))

  (add-to-fuzzy-list-org sym lst))

(defun fuzzy-list-enter ()
  (interactive)
  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (call-interactively 'add-to-fuzzy-list-org-enter)
    (call-interactively 'go-to-fuzzy-list-org)))

(defun go-to-fuzzy-list-org (&optional sym lst)
  ""
  (interactive (list
                (if mark-active
                    (pen-selected-text)
                  (esed "^\\*" "" (str (or (str (thing-at-point 'sexp))
                                           ""))))
                (cond
                 ((derived-mode-p 'prog-mode)
                  (concat "functions/" (detect-language))
                  )
                 (t (fz
                     (pen-snc (concat (pen-cmd "find" "$HOME/notes/ws/lists" "-type" "f" "-name" "*.org") "| path-lasttwo | sed \"s/\\\\..*//\""))
                     nil
                     nil
                     "add-to-fuzzy-list: ")))))

  (let ((fp (pen-umn (concat "$HOME/notes/ws/lists/" lst ".org")))
        (hn (concat "=" sym "="))
        )
    (with-current-buffer (e fp)
      (let ((hs (pen-org-list-top-level-headings)))
        (if (and sym lst)
            (if (-contains? hs hn)
                (pen-org-select-heading hn)
              (if (and hs (> 1 (length hs)))
                  (call-interactively 'helm-imenu))))))))
(defalias 'go-to-fuzzy-list 'go-to-fuzzy-list-org)
(defalias 'add-to-fuzzy-list 'add-to-fuzzy-list-org)

;; (define-key global-map (kbd "M-4 M-l") #'add-to-fuzzy-list)
(define-key selected-keymap (kbd "F") 'add-to-fuzzy-list)
;; (define-key global-map (kbd "H-f") 'fuzzy-list-enter)
(define-key selected-keymap (kbd "G") 'go-to-fuzzy-list-org)

(provide 'pen-fuzzy-lists)