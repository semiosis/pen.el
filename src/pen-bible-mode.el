(defun bible-open(&optional global-chapter verse module ref)
  "Creates and opens a `bible-mode' buffer"
  (interactive)
  (let
      (
       (buf (get-buffer-create (generate-new-buffer-name "*bible*"))))
    (set-buffer buf)
    (bible-mode)
    (if module
        (setq bible-mode-book-module module))
    (bible-mode--set-global-chapter (or global-chapter 1) verse)
    (set-window-buffer (get-buffer-window (current-buffer)) buf)

    (if (and ref
             (sor ref))
        (bible-mode-lookup ref))))

(defun bible-open-version (version)
  (interactive (list (completing-read "Module: " (bible-mode--list-biblical-modules))))
  (if (not version)
      (setq version "NASB"))

  (let ((bible-mode-book-module version))
    (bible-open nil nil version)))

(defun nasb ()
  (interactive)
  (bible-open-version "NASB"))

(defun kjv ()
  (interactive)
  (bible-open-version "KJV"))

(defun bsb ()
  (interactive)
  (bible-open-version "engbsb2020eb"))

(defun bible-get-text-here ()
  ;; Here, use scrape-bible-references

  (let* ((found
          (pen-str2list (pen-snc "scrape-bible-references | pen-sort line-length-desc" (thing-at-point 'line t))))
         (matched
          (-filter 'looking-at-p found)))

    (cond
     (matched (car matched))
     (found (car found))
     (t (thing-at-point 'line t)))))

(defun bible-mode-lookup (text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (bible-get-text-here)))

  (setq text (or text (bible-get-text-here)))

  ;; (mapcar 'car bible-mode-book-chapters)

  (cond
   ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    nil)
   ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?" text)
    (setq text (concat (match-string 0 text) ":")))
   ((re-match-p ".+ [0-9]?[0-9]?[0-9]?:" text)
    (setq text (concat text "1:")))
   ((re-match-p ".+ [0-9]?[0-9]?[0-9]?" text)
    (setq text (concat text ":1:")))
   ((re-match-p ".+ " text)
    (setq text (concat text "1:1:")))
   ((re-match-p ".+" text)
    (setq text (concat text " 1:1:"))))

  (let* (
         book
         chapter
         verse)
    (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    (setq text (match-string 0 text))

    (string-match " [0-9]?[0-9]?[0-9]?:" text)
    (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (string-match ":[0-9]?[0-9]?[0-9]?" text)
    (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))
    (setq book (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text))

    (tryelse
     (bible-open (+ (bible-mode--get-book-global-chapter book) (string-to-number chapter)) (string-to-number verse) bible-mode-book-module)
     (error "Error. Incorrect Bible reference?"))))

(defun bible-mode-copy-link (text)
  "Follows the hovered verse in a `bible-search-mode' buffer,
creating a new `bible-mode' buffer positioned at the specified verse."
  (interactive (list (thing-at-point 'line t)))
  (setq text (concat text ":"))
  (let* (
         book
         chapter
         verse)
    (string-match ".+ [0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:" text)
    (setq text (match-string 0 text))

    (string-match " [0-9]?[0-9]?[0-9]?:" text)
    (setq chapter (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))

    (string-match ":[0-9]?[0-9]?[0-9]?" text)
    (setq verse (replace-regexp-in-string "[^0-9]" "" (match-string 0 text)))
    (setq book (replace-regexp-in-string "[ ][0-9]?[0-9]?[0-9]?:[0-9]?[0-9]?[0-9]?:$" "" text))

    (if (>= (prefix-numeric-value current-prefix-arg) 4)
        (xc (concat "[[bible:" book " " chapter ":" verse "]]"))
      (xc (concat book " " chapter ":" verse)))))

(defun bible-mode--display(&optional verse)
  "Renders text for `bible-mode'"
  (interactive)
  (setq buffer-read-only nil)
  (erase-buffer)

  (insert (bible-mode--exec-diatheke (concat "Genesis " (number-to-string bible-mode-global-chapter)) nil nil nil bible-mode-book-module))

  (let* (
         (html-dom-tree (libxml-parse-html-region (point-min) (point-max))))
    (erase-buffer)
    (bible-mode--insert-domnode-recursive (dom-by-tag html-dom-tree 'body) html-dom-tree)
    (goto-char (point-min))
    (while (search-forward (concat "(" bible-mode-book-module ")") nil t)
      (replace-match "")))

  (setq mode-name (concat "Bible (" bible-mode-book-module ")"))
  (setq buffer-read-only t)
  (goto-char (point-min))
  ;; (tv (concat ":" (number-to-string verse) ": "))
  (if verse
      (progn
        ;; Can't use ": " because sometimes like with Psalms 40:1
        ;; there is no space
        (goto-char (string-match (regexp-opt `(,(concat ":" (number-to-string verse) ":"))) (buffer-string)))
        (beginning-of-line))))

(define-key bible-mode-map (kbd "d") 'bible-mode-toggle-word-study)
(define-key bible-mode-map (kbd "w") 'bible-mode-copy-link)

(define-key bible-mode-map "n" 'bible-mode-next-chapter)
(define-key bible-mode-map "p" 'bible-mode-previous-chapter)
(define-key bible-mode-map "b" 'bible-mode-select-book)
(define-key bible-mode-map "g" 'bible-mode--display)
(define-key bible-mode-map "c" 'bible-mode-select-chapter)
(define-key bible-mode-map "s" 'bible-search)
(define-key bible-mode-map "m" 'bible-mode-select-module)
(define-key bible-mode-map "x" 'bible-mode-split-display)

(define-key bible-search-mode-map "s" 'bible-search)
(define-key bible-search-mode-map "w" 'bible-mode-toggle-word-study)
(define-key bible-search-mode-map (kbd "RET") 'bible-search-mode-follow-verse)

(define-key bible-mode-greek-keymap (kbd "RET") (lambda ()
                                                  (interactive)
                                                  (bible-term-greek (replace-regexp-in-string "[^0-9]*" "" (thing-at-point 'word t)))))

(define-key bible-mode-lemma-keymap (kbd "RET") (lambda ()(interactive)))

(define-key bible-mode-hebrew-keymap (kbd "RET") (lambda ()
                                                   (interactive)
                                                   (bible-term-hebrew (replace-regexp-in-string "[a-z]+" "" (thing-at-point 'word t)))))

(define-key global-map (kbd "H-v") 'nasb)
(define-key bible-mode-map (kbd "v") 'bible-mode-select-module)

(provide 'pen-bible-mode)
