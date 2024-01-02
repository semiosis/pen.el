(require 'annotate)

;; annotate.el already has Info-mode support

(defun enable-annotate ()
  ;; This is all that's needed
  (progn-read-only-disable
   (annotate-mode 1))

  ;; (pen-ns (buffer-name))
  ;; (pen-ns "loading")
  ;; (pen-annotate-draw)
  ;; (progn-read-only-disable
  ;;  (annotate-initialize)
  ;;  ;; (annotate-initialize-maybe)
  ;;  )
  ;; (font-lock-fontify-buffer)

  ;; (annotate-load-annotations-command)
  )

;; Use manage minor mode? -- can't. prog-mode, conf-mode wont stick, because manage minor mode doesn't work for parent modes
;; v +/";; THis doesnt work" "$EMACSD/config/pen-manage-minor-mode.el"


(defun pen-after-save-actions ()
  "Used in `after-save-hook'."
  (when (memq this-command '(save-buffer save-some-buffers))
    ;; put a copy of the current file in a specific folder...
    ))

;; annotate.el already has Info-mode support
;; But dired-mode isn't really working

;; This appears to not work on all buffer types until the buffer contents has been loaded.
;; Therefore, adding to these hooks seems a bit useless.
;; Try adding annotate to eww
;; dired-mode doesn't work here. I think it's because it preloads the buffer in the background then selects it
;; The hook happens before the buffer is selected.
;; Perhaps I can do a save-window-excursion and select the buffer temporarily instead
(defset modes-for-annotate-mode '(Info-mode-hook helpful-mode help-mode prog-mode conf-mode text-mode yaml-mode ssh-config-mode
                                                 bible-mode))

(cl-loop for m in modes-for-annotate-mode do
         ;; (message (str m))
         (let ((h (intern (concat (symbol-name m) "-hook"))))
           (add-hook h 'enable-annotate t)))

;; This works, though
(defun dired-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (enable-annotate)
    (try (generate-glossary-buttons-over-buffer nil nil)
         nil)
    res))
(advice-add 'dired :around #'dired-around-advice)
;; (advice-remove 'dired #'dired-around-advice)


;; This was breaking eww buttons
;; (add-hook 'eww-after-render-hook #'enable-annotate)
;; (remove-hook 'eww-after-render-hook #'enable-annotate)

;; (add-hook 'dired-load-hook #'enable-annotate)
;; (remove-hook 'dired-load-hook #'enable-annotate)

;; This is the very end of dired-mode. It's where I want to load it
;; (add-hook 'dired-mode-hook #'enable-annotate)
;; (remove-hook 'dired-mode-hook #'enable-annotate)

(add-hook 'Info-mode-hook #'enable-annotate)

;; (add-hook 'spacemacs-buffer-mode-hook #'enable-annotate)
;; (remove-hook 'spacemacs-buffer-mode-hook #'enable-annotate)
;; (add-hook 'dashboard-mode-hook #'enable-annotate)
;; (remove-hook 'dashboard-mode-hook #'enable-annotate)
;; (add-hook 'elfeed-search-mode-hook #'enable-annotate)
;; (remove-hook 'elfeed-search-mode-hook #'enable-annotate)

;; (defset modes-for-annotate-mode '(helpful-mode))
;; (cl-loop for m in modes-for-annotate-mode do
;;          ;; (message (str m))
;;          (let ((h (intern (concat (symbol-name m) "-hook"))))
;;            (add-hook h 'enable-annotate)))


;; (defset modes-for-annotate-mode-remove '(dired-mode help-mode))
;; (cl-loop for m in modes-for-annotate-mode do
;;          ;; (message (str m))
;;          (let ((h (intern (concat (symbol-name m) "-hook"))))
;;            (remove-hook h 'enable-annotate)))



(defun pen-annotate-list-buffer-annotations-in-memory ()
  (cl-remove-if (λ (a)
                  (= (annotate-beginning-of-annotation a)
                     (annotate-ending-of-annotation a)))
                (annotate-describe-annotations)))


;; (defun save-if-annotate-mode ()
;;   (if (bound-and-true-p annotate-mode)
;;       (shut-up (annotate-save-annotations))))

;; (add-hook 'after-save-hook 'pen-after-save-actions)


(defun if-annotating-save-annotations ()
  (if (bound-and-true-p annotate-mode)
      (annotate-save-annotations)))

(define-key annotate-mode-map (kbd "C-c C-a") nil)
(define-key annotate-mode-map (kbd "C-c [") nil)
(define-key annotate-mode-map (kbd "C-c ]") nil)
(define-key annotate-mode-map (kbd "C-c s") nil)

(defun pen-annotate ()
       (interactive)
       (annotate-annotate)
       (shut-up (annotate-save-annotations)))

(defun annotate-annotate-around-advice (proc &rest args)
  (if (and (eolp) (not (bolp)))
      (save-excursion
        (backward-char)
        (let ((res (apply proc args))) res))
    (let ((res (apply proc args))) res)))
(advice-add 'annotate-annotate :around #'annotate-annotate-around-advice)



;; annotations sometimes produce huge error messages in the modeline
;; Currently happening with todo.org
;; Therefore, I have to cover it up.
(defun annotate-load-annotations-around-advice (proc &rest args)
  ;; (shut-up (let ((res (apply proc args)))
  ;;               res))
  (shut-up (ignore-errors (let ((res (apply proc args)))
                               res)))
  ;; (let ((res (apply proc args)))
  ;;   res)
  )
(advice-add 'annotate-load-annotations :around #'annotate-load-annotations-around-advice)
;; (advice-remove 'annotate-load-annotations  #'annotate-load-annotations-around-advice)


(defun annotate-show-annotation-summary-immediate ()
  (interactive)
  (annotate-show-annotation-summary ""))

(defun annotate-load-annotations-command ()
  (interactive)
  ;; This way, it will properly clear the annotations before loading again, so it doesn't stack

  (progn-read-only-disable
   (annotate-mode -1)
   (annotate-mode 1))

  ;; This would stack the annotations. Bad.
  ;; (annotate-load-annotations)

  (message "annotations loaded"))


;; This allows you to edit annotations in Info-mode
(defun annotate-annotate-around-advice (proc &rest args)
  (let ((res (progn-read-only-disable (apply proc args))))
    res))
(advice-add 'annotate-annotate :around #'annotate-annotate-around-advice)

;; (define-key annotate-mode-map (kbd "H-a") 'pen-annotate)
;; (define-key annotate-mode-map (kbd "H-A") 'annotate-annotate)
(define-key annotate-mode-map (kbd "H-a") 'annotate-annotate)
(define-key annotate-mode-map (kbd "H-A n") 'annotate-goto-next-annotation)
(define-key annotate-mode-map (kbd "H-A p") 'annotate-goto-previous-annotation)
(define-key annotate-mode-map (kbd "H-]") 'annotate-goto-next-annotation)
(define-key annotate-mode-map (kbd "H-[") 'annotate-goto-previous-annotation)
(define-key annotate-mode-map (kbd "C-c ]") 'annotate-goto-next-annotation)
(define-key annotate-mode-map (kbd "C-c [") 'annotate-goto-previous-annotation)
(define-key annotate-mode-map (kbd "H-A m") 'annotate-show-annotation-summary)
(define-key annotate-mode-map (kbd "H-A h") 'annotate-show-annotation-summary-immediate)
(define-key global-map (kbd "H-A S") 'annotate-show-annotation-summary-immediate)
(define-key annotate-mode-map (kbd "H-A l") 'annotate-load-annotations-command)
(define-key annotate-mode-map (kbd "H-A s") 'annotate-save-annotations)
(define-key annotate-mode-map (kbd "H-A c") 'annotate-clear-annotations)
(define-key annotate-mode-map (kbd "H-A x") 'annotate-integrate-annotations)

;; (remove-hook 'prog-mode-hook 'enable-annotate)
;; (remove-hook 'conf-mode-hook 'enable-annotate)
;; (remove-hook 'text-mode-hook 'enable-annotate)
;; (remove-hook 'yaml-mode-hook 'enable-annotate)
;; (remove-hook 'ssh-config-mode-hook 'enable-annotate)


;; I had to re-enable local-map
(defun annotate-show-annotation-summary (&optional arg-query)
 "Show a summary of all the annotations in a temp buffer, the
results can be filtered with a simple query language: see
`annotate-summary-filter-db'."
  (interactive)
  (cl-labels ((ellipsize (text prefix-string)
                         (let* ((prefix-length   (string-width prefix-string))
                                (ellipse-length  (string-width annotate-ellipse-text-marker))
                                (substring-limit (max 0
                                                      (- (window-body-width)
                                                         prefix-length
                                                         ellipse-length
                                                         2)))) ; this is for quotation marks
                           (if (> (string-width text)
                                  substring-limit)
                               (concat (substring text 0 substring-limit)
                                       annotate-ellipse-text-marker)
                             text)))
              (wrap      (text)
                         (concat "\"" text "\""))
              (insert-item-summary (filename
                                    snippet-text
                                    button-text
                                    annotation-beginning
                                    annotation-ending
                                    filter-query)
                                   (insert annotate-summary-list-prefix-snippet)
                                   (insert (wrap (ellipsize snippet-text
                                                            annotate-summary-list-prefix-snippet)))
                                   (insert "\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert-button (propertize (ellipsize button-text
                                                                         annotate-summary-list-prefix)
                                                              'face
                                                              'bold)
                                                  'file   filename
                                                  'go-to  annotation-beginning
                                                  'action 'annotate-summary-show-annotation-button-pressed
                                                  'type   'annotate-summary-show-annotation-button)
                                   (insert "\n\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert "  ")
                                   (let ((del-button (insert-button
                                                       annotate-summary-delete-button-label
                                                      'file       filename
                                                      'beginning  annotation-beginning
                                                      'ending     annotation-ending
                                                      'action
                                                      'annotate-summary-delete-annotation-button-pressed
                                                      'type
                                                      'annotate-summary-delete-annotation-button)))
                                     (button-put del-button
                                                 'begin-of-button
                                                 (annotate-beginning-of-line-pos))
                                     (button-put del-button
                                                 'end-of-button
                                                 (annotate-end-of-line-pos)))
                                   (insert "\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert "  ")
                                   (insert-button annotate-summary-replace-button-label
                                                  'file       filename
                                                  'beginning  annotation-beginning
                                                  'ending     annotation-ending
                                                  'query      filter-query
                                                  'text       button-text
                                                  'action
                                                  'annotate-summary-replace-annotation-button-pressed
                                                  'type
                                                  'annotate-summary-replace-annotation-button)
                                   (insert "\n\n"))
              (clean-snippet (snippet)
                             (save-match-data
                               (replace-regexp-in-string "[\r\n]"
                                                         " "
                                                         snippet)))
              (build-snippet-info (filename annotation-begin annotation-end)
                                  (with-temp-buffer
                                    (info-setup filename (current-buffer))
                                    (buffer-substring-no-properties annotation-begin
                                                                    annotation-end)))
              (build-snippet (filename annotation-begin annotation-end)
                             (if (file-exists-p filename)
                                 (cond
                                  ((eq (annotate-guess-file-format filename)
                                        :info)
                                   (clean-snippet (build-snippet-info filename
                                                                      annotation-begin
                                                                      annotation-end)))
                                  (t
                                   (with-temp-buffer
                                     (insert-file-contents filename
                                                           nil
                                                           (1- annotation-begin)
                                                           (1- annotation-end))
                                     (clean-snippet (buffer-string)))))
                               (if (annotate-info-root-dir-p filename)
                                   (clean-snippet (build-snippet-info filename
                                                                      annotation-begin
                                                                      annotation-end))
                                 annotate-error-summary-win-filename-invalid)))
              (db-empty-p    (dump)
                             (cl-every (λ (a)
                                         (cl-every 'null
                                                   (annotate-annotations-from-dump a)))
                                       dump))
              (get-query     ()
                             (cond
                              (arg-query
                               arg-query)
                              (annotate-summary-ask-query
                               (read-from-minibuffer "Query: "))
                              (t
                               ".*"))))
    (let* ((filter-query (get-query))
           (dump         (annotate-summary-filter-db (annotate-load-annotation-data)
                                                     filter-query)))
      (if (db-empty-p dump)
          (when annotate-use-messages
            (message "The annotation database is empty"))
        (with-current-buffer-window
         annotate-summary-buffer-name nil nil
         (display-buffer annotate-summary-buffer-name)
         (select-window (get-buffer-window annotate-summary-buffer-name t))
         (outline-mode)
         ;; (use-local-map nil)
         (local-set-key "q" (λ ()
                              (interactive)
                              (kill-buffer annotate-summary-buffer-name)
                              (local-unset-key "q")))
         (dolist (annotation dump)
           (let* ((all-annotations (annotate-annotations-from-dump annotation))
                  (db-filename     (annotate-filename-from-dump annotation)))
             (when (not (null all-annotations))
               (insert (format (concat annotate-summary-list-prefix-file "%s\n\n")
                               db-filename))
               (dolist (annotation-field all-annotations)
                 (let* ((button-text      (format "%s"
                                                  (annotate-annotation-string annotation-field)))
                        (annotation-begin (annotate-beginning-of-annotation annotation-field))
                        (annotation-end   (annotate-ending-of-annotation    annotation-field))
                        (snippet-text     (build-snippet db-filename
                                                         annotation-begin
                                                         annotation-end)))
                   (insert-item-summary db-filename
                                        snippet-text
                                        button-text
                                        annotation-begin
                                        annotation-end
                                        filter-query))))))
         (read-only-mode 1))))))


;; Change from find-file-other-window to find-file
(defun annotate-summary-show-annotation-button-pressed (button)
  "Callback called when an annotate-summary-show-annotation-button is activated"
  (let* ((file      (button-get button 'file))
         (file-type (annotate-guess-file-format file)))
    (cond
     ((eq file-type :info)
      (with-current-buffer-window
       "*info*" nil nil
       (info-setup file (current-buffer))
       (switch-to-buffer "*info*"))
      (with-current-buffer "*info*"
        (goto-char (button-get button 'go-to))))
     (t
      (let* ((buffer (find-file file)))
        (with-current-buffer buffer
          (goto-char (button-get button 'go-to))))))))


(setq annotate-file (locate-user-emacs-file "annotations" ".annotations"))


(defun annotate-path-filter-p (s)
  (try (and (not (string-match-p "^/tmp/" (str (car s)))) (cadr s))
       t))

;; This makes it so the .annotaitons file is prettied up
;; It's slower but I can use it this way sometimes
;; I can also debug why it gets slow and filter out files pen-i don't want
(defun annotate-dump-annotation-data (data)
  "Save `data` into annotation file."
  (with-temp-file annotate-file
    (let ((print-length nil))
      ;; (tv (chomp (pp (-filter (λ (s) (not (string-match-p "^/tmp/" (str (car s))))) data))))
      (chomp (pp (-filter 'annotate-path-filter-p data) (current-buffer)))
      ;; (prin1 data (current-buffer))
      )))


(defun annotate-actual-file-name ()
  "Get the actual file name of the current buffer"
  (substring-no-properties (or (annotate-info-actual-filename)
                               (string-or (buffer-file-name))
                               (string-or (if (derived-mode-p 'eww-mode) (concat "**" (get-path))))
                               (string-or
                                (try
                                 (concat "**" (cond ((derived-mode-p 'dired-mode) (slugify (concat (str (buffer-mode)) "-" (pen-mnm (pen-pwd)) "-" (buffer-name))))
                                                    (t (slugify (concat (str (buffer-mode)) "-" (buffer-name))))))
                                 ""))
                               "")))


(defun annotate-show-annotation-summary (&optional arg-query)
 "Show a summary of all the annotations in a temp buffer, the
results can be filtered with a simple query language: see
`annotate-summary-filter-db'."
  (interactive)
  (cl-labels ((ellipsize (text prefix-string)
                         (let* ((prefix-length   (string-width prefix-string))
                                (ellipse-length  (string-width annotate-ellipse-text-marker))
                                (substring-limit (max 0
                                                      (- (window-body-width)
                                                         prefix-length
                                                         ellipse-length
                                                         2)))) ; this is for quotation marks
                           (if (> (string-width text)
                                  substring-limit)
                               (concat (substring text 0 substring-limit)
                                       annotate-ellipse-text-marker)
                             text)))
              (wrap      (text)
                         (concat "\"" text "\""))
              (insert-item-summary (filename
                                    snippet-text
                                    button-text
                                    annotation-beginning
                                    annotation-ending
                                    filter-query)
                                   (insert annotate-summary-list-prefix-snippet)
                                   (insert (wrap (ellipsize snippet-text
                                                            annotate-summary-list-prefix-snippet)))
                                   (insert "\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert-button (propertize (ellipsize button-text
                                                                         annotate-summary-list-prefix)
                                                              'face
                                                              'bold)
                                                  'file   filename
                                                  'go-to  annotation-beginning
                                                  'action 'annotate-summary-show-annotation-button-pressed
                                                  'type   'annotate-summary-show-annotation-button)
                                   (insert "\n\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert "  ")
                                   (let ((del-button (insert-button
                                                       annotate-summary-delete-button-label
                                                      'file       filename
                                                      'beginning  annotation-beginning
                                                      'ending     annotation-ending
                                                      'action
                                                      'annotate-summary-delete-annotation-button-pressed
                                                      'type
                                                      'annotate-summary-delete-annotation-button)))
                                     (button-put del-button
                                                 'begin-of-button
                                                 (annotate-beginning-of-line-pos))
                                     (button-put del-button
                                                 'end-of-button
                                                 (annotate-end-of-line-pos)))
                                   (insert "\n")
                                   (insert annotate-summary-list-prefix)
                                   (insert "  ")
                                   (insert-button annotate-summary-replace-button-label
                                                  'file       filename
                                                  'beginning  annotation-beginning
                                                  'ending     annotation-ending
                                                  'query      filter-query
                                                  'text       button-text
                                                  'action
                                                  'annotate-summary-replace-annotation-button-pressed
                                                  'type
                                                  'annotate-summary-replace-annotation-button)
                                   (insert "\n\n"))
              (clean-snippet (snippet)
                             (save-match-data
                               (replace-regexp-in-string "[\r\n]"
                                                         " "
                                                         snippet)))
              (build-snippet-info (filename annotation-begin annotation-end)
                                  (with-temp-buffer
                                    (info-setup filename (current-buffer))
                                    (buffer-substring-no-properties annotation-begin
                                                                    annotation-end)))
              (build-snippet (filename annotation-begin annotation-end)
                             (cond
                              ((string-match-p "^\\*\\*" filename)
                               "N/A")
                              ((eq (annotate-guess-file-format filename)
                                   :info)
                               (clean-snippet (build-snippet-info filename
                                                                  annotation-begin
                                                                  annotation-end)))
                              (t
                               (with-temp-buffer
                                 (insert-file-contents filename
                                                       nil
                                                       (1- annotation-begin)
                                                       (1- annotation-end))
                                 (clean-snippet (buffer-string)))))
                             ;; (if (annotate-info-root-dir-p filename)
                             ;;     (clean-snippet (build-snippet-info filename
                             ;;                                        annotation-begin
                             ;;                                        annotation-end))
                             ;;   annotate-error-summary-win-filename-invalid)
                             )
              (db-empty-p    (dump)
                             (cl-every (λ (a)
                                         (cl-every 'null
                                                   (annotate-annotations-from-dump a)))
                                       dump))
              (get-query     ()
                             (cond
                              (arg-query
                               arg-query)
                              (annotate-summary-ask-query
                               (read-from-minibuffer "Query: "))
                              (t
                               ".*"))))
    (let* ((filter-query (get-query))
           (dump         (annotate-summary-filter-db (annotate-load-annotation-data)
                                                     filter-query)))
      (if (db-empty-p dump)
          (when annotate-use-messages
            (message "The annotation database is empty"))
        (with-current-buffer-window
         annotate-summary-buffer-name nil nil
         (display-buffer annotate-summary-buffer-name)
         (select-window (get-buffer-window annotate-summary-buffer-name t))
         (outline-mode)

         ;; This solved a problem where "q" binding was being defined for org-mode
         ;; But it also disables outline-mode bindings. Therefore I must find another workaround
         ;; (use-local-map nil)

         ;; Just don't bind this
         ;; (local-set-key "q" (λ ()
         ;;                      (interactive)
         ;;                      (kill-buffer annotate-summary-buffer-name)))

         (dolist (annotation dump)
           (let* ((all-annotations (annotate-annotations-from-dump annotation))
                  (db-filename     (annotate-filename-from-dump annotation)))
             (when (not (null all-annotations))
               (insert (format (concat annotate-summary-list-prefix-file "%s\n\n")
                               db-filename))
               (dolist (annotation-field all-annotations)
                 (let* ((button-text      (format "%s"
                                                  (annotate-annotation-string annotation-field)))
                        (annotation-begin (annotate-beginning-of-annotation annotation-field))
                        (annotation-end   (annotate-ending-of-annotation    annotation-field))
                        (snippet-text     (build-snippet db-filename
                                                         annotation-begin
                                                         annotation-end)))
                   (insert-item-summary db-filename
                                        snippet-text
                                        button-text
                                        annotation-begin
                                        annotation-end
                                        filter-query))))))
         (read-only-mode 1))))))


(defun pen-annotate-draw ()
  (interactive)
  (annotate-load-annotations)
  (font-lock-add-keywords
   nil
   '((annotate--font-lock-matcher (2 (annotate--annotation-builder))
                                  (1 (annotate--change-guard))))))


(defun annotate-initialize ()
  "Load annotations and set up save and display hooks."
  (annotate-load-annotations)
  (add-hook 'after-save-hook                  'annotate-save-annotations t t)
  (add-hook 'window-configuration-change-hook 'font-lock-fontify-buffer  t t)
  (add-hook 'before-change-functions          'annotate-before-change-fn t t)
  (add-hook 'Info-selection-hook              'annotate-info-select-fn   t t)
  ;; (add-hook 'dired-mode-hook              'annotate-info-select-fn   t t)
  (font-lock-add-keywords
   nil
   '((annotate--font-lock-matcher (2 (annotate--annotation-builder))
                                  (1 (annotate--change-guard))))))

(defun annotate-initialize-maybe ()
  "Initialize annotate mode only if buffer's major mode is not in the blacklist (see:
'annotate-blacklist-major-mode'"
  (let ((annotate-allowed-p (with-current-buffer (current-buffer)
                              (not (cl-member major-mode annotate-blacklist-major-mode)))))
    (cond
     ((not annotate-allowed-p)
      (annotate-shutdown)
      (setq annotate-mode nil))
     ;; ((and annotate-mode (read-only-mode))
     ;;  (read-only-mode -1)
     ;;  (when (not (annotate-annotations-exist-p))
     ;;    (annotate-initialize))
     ;;  (read-only-mode 1))
     (annotate-mode
      (when (not (annotate-annotations-exist-p))
        (annotate-initialize)))
     (t
      (annotate-shutdown)))))

;; (defun annotate-initialize-maybe ()
;;   "Initialize annotate mode only if buffer's major mode is not in the blacklist (see:
;; 'annotate-blacklist-major-mode'"
;;   (annotate-shutdown)
;;   ;; (setq annotate-mode nil)
;;   (annotate-initialize))


(defun pen-annotate-find-buffer-visiting ()
  ;; Making this find virtual buffers would be a nice TODO
  (find-buffer-visiting filename))

;; (defun pen-reload-annotate ()
;;   (interactive)
;;   (annotate-mode -1)
;;   (annotate-mode 1))

;; TODO Make it so when an annotation is deleted, it looks for buffers too with the virtual file names
(defun annotate-summary-delete-annotation-button-pressed (button)
  (let* ((filename        (button-get button 'file))
         (beginning       (button-get button 'beginning))
         (ending          (button-get button 'ending))
         (begin-of-button (button-get button 'begin-of-button))
         (end-of-button   (button-get button 'end-of-button))
         (db              (annotate-load-annotation-data))
         (filtered        (annotate-db-remove-annotation db filename beginning ending)))
    (annotate-dump-annotation-data filtered) ; save the new database with entry removed
    (cl-labels ((redraw-summary-window ()    ; update the summary window
                                       (with-current-buffer annotate-summary-buffer-name
                                         (read-only-mode -1)
                                         (save-excursion
                                           (button-put button 'invisible t)
                                           (let ((annotation-button (previous-button (point))))
                                             (button-put annotation-button 'face '(:strike-through t)))
                                           (let ((replace-button (next-button (point))))
                                             (button-put replace-button 'invisible t)))
                                         (read-only-mode 1)))
                ;; if the file where the  deleted annotation belong to is visited,
                ;; update the buffer
                (update-visited-buffer-maybe ()
                                             (let ((visited-buffer (pen-annotate-find-buffer-visiting filename)))
                                               (when visited-buffer ;; a buffer is visiting the file
                                                 (with-current-buffer visited-buffer
                                                   (annotate-mode -1)
                                                   (annotate-mode  1))))))
      (redraw-summary-window)
      (update-visited-buffer-maybe))))



(defvar annotate-kill-buffer-after-hook '())
(defun annotate-kill-buffer-after-advice (&rest args)
  (run-hooks 'annotate-kill-buffer-after-hook))
(advice-add 'pen-revert-kill-buffer-and-window :after 'annotate-kill-buffer-after-advice)
(advice-add 'kill-buffer-immediately :after 'annotate-kill-buffer-after-advice)
(add-hook 'annotate-kill-buffer-after-hook 'if-annotating-save-annotations)

;; (add-hook 'kill-buffer-hook 'if-annotating-save-annotations)
;; (remove-hook 'kill-buffer-hook 'if-annotating-save-annotations)


;; This fixed a bug that rather annoyingly sometimes deleted key bindings when pen-i made a newline
(defun annotate--remove-annotation-property-around-advice (proc &rest args)
  (let ((res (ignore-errors (apply proc args))))
    res))
(advice-add 'annotate--remove-annotation-property :around #'annotate--remove-annotation-property-around-advice)

(provide 'pen-annotate)
