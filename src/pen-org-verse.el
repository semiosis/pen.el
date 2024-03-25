;; https://github.com/DarkBuffalo/org-verse

;; (etv (filter-cmd-collect "scrape-bible-references" nil))

(defconst org-verse-mode-keymap (make-keymap))
(define-key org-verse-mode-keymap (kbd "C-c /") #'org-verse-buttonize-buffer)

(define-button-type 'org-verse-button
  'action #'org-verse-button-verse
  'follow-link t
  'face 'org-verse-number-face
  'help-echo "Clic le boutton pour lire le verset."
  'help-args "test")

(defun org-verse-button-verse (button)
  "BUTTON verse."
  (let ((refverse (button-get button 'title))
        (book (button-get button 'book))
        (chapter (button-get button 'chapter))
        (verses (button-get button 'verses)))

    (tpop-fit-vim-string (pen-snc (cmd "bible-tpop-lookup" "-c" "-m" "KJV"
                                       (concat
                                        book " " chapter ":" verses))))

    ;; si buffer pas ouvert, ouvrir sinon mettre a jour
    (comment
     (if (window-live-p (get-buffer-window org-verse-buffer))
         (org-verse-sidebar-refresh refverse book chapter verses)
       (org-verse-toggle-sidebar)
       (org-verse-sidebar-refresh refverse book chapter verses)))))

(defset org-verse-pattern
        (eval
         `(rx
           ,(list 'group
                  (cons 'or
                        (mapcar
                         (lambda (tp) (cons 'or tp))
                         bible-book-map-names)))
           space
           (group (1+ digit))
           ":"
           (group (or
                   (group (group (any digit)) "-" (group (1+ digit) ":" (1+ digit)))
                   (group (1+ (1+ digit) (0+
                                          (or ","
                                              "-"))))))))
        "Generic regexp for number highlighting.
It is used when no mode-specific one is available.")

(defun org-verse-buttonize-buffer ()
  "Turn all verse into button."
  ;; For some reason, overlays accumulate if a buffer
  ;; is visited another time, making emacs slower and slower.
  ;; Hack is to remove them all first.
  ;; remove-overlays does not seem to exist for older emacsen (<23.x.x?)
  (interactive)
  (with-writable-buffer
   (if (fboundp 'remove-overlays)
       (remove-overlays))

   (save-excursion
     (goto-char (point-min))
     (while (search-forward-regexp org-verse-pattern nil t)
       ;;recuperer le contenu de la recherche pour le mettre en titre
       ;;https://github.com/Kinneyzhang/gkroam/blob/b40555f45a844b8fefc419cd43dc9bf63205a0b4/gkroam.el#L708
       (let ((title (match-string-no-properties 0))
             (book (match-string-no-properties 1))
             (chapter (match-string-no-properties 2))
             (verses (match-string-no-properties 3)))
         ;;créer les bouttons
         (make-text-button (match-beginning 0)
                           (match-end 0)
                           :type 'org-verse-button
                           ;;inserer le titre recuperer plus haut
                           'title title
                           'book book
                           'chapter chapter
                           'verses verses))))))

(define-minor-mode org-verse-mode "Highlight bible verses."
  :init-value nil
  :lighter " verse"
  :keymap org-verse-mode-keymap
  :group 'verse
  (org-verse--turn-off)
  (if org-verse-mode
      (progn
        (org-verse--turn-on)
        (add-hook 'after-save-hook #'org-verse-buttonize-buffer)))

  (when font-lock-mode
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

;; (add-hook 'org-verse-mode-hook
;;           (function
;;            (lambda ()
;;              (setq case-fold-search t))))

(add-hook 'org-mode-hook 'org-verse-mode)

(provide 'pen-org-verse)
