(require 'org-brain)
(require 'pen-support)

(defalias 'org-brain-entry-to-string 'org-brain-entry-name)

(defset org-brains-dir "~/.pen/org-brain")

(setq org-directory (f-join pen-confdir "documents"))
;; But there can be multiple root directories for org-brain
;; So let's just set here the default one for 'agenda'

;; org-brain-path and org-brain-data-file should be set again when I switch org-brain
(setq org-brain-path (file-truename (f-join (expand-file-name "org-brain" pen-confdir) "agenda")))
(setq org-brain-data-file (file-truename (expand-file-name ".org-brain-data.el" org-brain-path)))

(setq org-brain-completion-system 'ivy)
;; (setq org-brain-completion-system 'helm)

(ignore-errors
  (mkdir org-brains-dir)
  (mkdir (f-join org-brains-dir "billboard")))

;; To fix a dependency
(require 'org-indent)

;; To fix a dependency
(require 'org-capture)

(defset pen-org-brain-list '())
(defset pen-org-brain-shortcut-list '())
(defset pen-org-brain-local-shortcut-list '())

(defalias 'obeft 'org-brain-entry-from-text)
(defalias 'obvrm 'org-brain-visualize-reset-map)
(defalias 'obsb 'pen-org-brain-switch-brain)
(defalias 'esed 'replace-regexp-in-string)

(use-package org-brain :ensure t
  :init
  (setq org-brain-path (f-join org-brains-dir "agenda"))
  :config
  (setq org-id-track-globally t)
  (test-f "$EMACSD_BUILTIN/.org-id-locations")
  (setq org-id-locations-file "~/.emacs.d/.org-id-locations")
  (push '("b" "Brain" plain (function org-brain-goto-end)
          "* %i%?" :empty-lines 1)
        org-capture-templates)
  (setq org-brain-visualize-default-choices 'all)
  (setq org-brain-title-max-length 30))

(defsetface org-brain-title
  '((t :foreground "#999999"
       ;; :background "#2e2e2e"
       :weight bold
       :underline nil))
  "Face for org-brain-title (not a button).")

(defsetface org-brain-parent
  '((t :foreground "#dd4444"
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for org-brain-parent buttons.")

(defsetface org-brain-history-list
  '((t :foreground "#dd4400"
       ;; It's better for the glossary buttons to have no background, so normal syntax things, such as LSP highlighting can still be visible
       ;; underline is enough
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for org-brain-child buttons.")

(defsetface org-brain-child
  '((t :foreground "#dd4400"
       ;; It's better for the glossary buttons to have no background, so normal syntax things, such as LSP highlighting can still be visible
       ;; underline is enough
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for org-brain-child buttons.")

(defsetface org-brain-local-child
  '((t :foreground "#4444dd"
       ;; It's better for the glossary buttons to have no background, so normal syntax things, such as LSP highlighting can still be visible
       ;; underline is enough
       ;; :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for org-brain-local-child buttons.")

(defsetface org-brain-wires
  `((t . (:inherit 'font-lock-comment-face :italic nil)))
  "Face for the wires connecting entries.")

(defsetface org-brain-file-face-template
  '((t . (
          :foreground "#888800"
          ;; :slant italic
                      )))
  "Attributes of this face are added to file-entry faces.")

(defun org-brain-list-child-nodes ()
  "child files"
  (interactive)
  (let ((l
         (-uniq
          (append
           (org-brain-children org-brain--vis-entry)
           (org-brain-local-children org-brain--vis-entry)))))
    (if (interactive-p)
        (pen-etv l)
      l)))

(defun org-brain-local-children (entry)
  "Get file local children of ENTRY."
  (remove
   entry
   (if (org-brain-filep entry)
       ;; File entry
       (with-temp-buffer
         (ignore-errors (insert-file-contents (org-brain-entry-path entry)))
         (org-element-map (org-element-parse-buffer 'headline) 'headline
           (lambda (headline)
             (when-let ((id (org-element-property :ID headline)))
               (unless (org-brain-id-exclude-taggedp id)
                 (org-brain-entry-from-id id))))
           nil nil 'headline))
     ;; Headline entry
     (org-with-point-at (org-brain-entry-marker entry)
       (let (children)
         (deactivate-mark)
         (org-mark-subtree)
         (org-goto-first-child)
         ;; I've added this level check
         ;; becuase there seems to be a bug
         ;; with org-map-entries and 'region-start-level
         (let ((level (org-current-level)))
           (setq children
                 (org-map-entries
                  (lambda ()
                    (cons
                     (org-current-level)
                     (org-brain-entry-from-id (org-entry-get nil "ID"))))
                  t 'region-start-level
                  (lambda ()
                    (let ((id (org-entry-get nil "ID")))
                      (when (and
                             (or (not id)
                                 (org-brain-id-exclude-taggedp id))
                             (eq level (org-current-level)))
                        (save-excursion
                          (outline-next-heading)
                          (point)))))))
           (deactivate-mark)
           (mapcar
            'cdr
            (-filter (lambda (e) (eq (car e)
                                     level))
                     children))))))))

(defun org-brain-list-child-headings ()
  "local-child / heading"
  (interactive)
  (pen-etv (-uniq
            (-uniq-d
             (append
              (org-brain-children org-brain--vis-entry)
              (org-brain-local-children org-brain--vis-entry))))))

(defun org-brain-headline-at-point ()
  (let ((b (button-at-point))
        (p org-brain--vis-entry))
    (if (and b (button-face-p-here 'org-brain-local-child))
        (progn
          (car (-filter
                (lambda (e)
                  (and (equal (car e) org-brain--vis-entry))
                  (equal (second e) (str (pen-button-get-text b))))
                (org-brain-headline-entries)))))))

(defun org-brain-file-at-point ()
  (let ((b (button-at-point))
        (p org-brain--vis-entry))
    (and b (button-face-p-here 'org-brain-child))))

(defun org-brain-this-headline-to-file ()
  (interactive)
  (let ((h (org-brain-headline-at-point)))
    (if h
        (progn
          (org-brain-headline-to-file h)
          (revert-buffer)

          (org-brain-update-id-locations)))))

(defun org-brain-visualize-goto (&optional entry)
  ""
  (interactive)
  (org-brain-stop-wandering)
  (unless entry (setq entry (org-brain-choose-entry "Goto entry: " 'all)))
  (org-brain-visualize entry))

(defun org-brain-associates (entry)
  "Get children of ENTRY."
  (delete-dups
   (append (org-brain--linked-property-entries entry org-brain-children-property-name)
           (org-brain-local-children entry)
           (org-brain-friends entry)
           (org-brain-parents entry))))

(defun org-brain-visualize-goto-associate (entry)
  ""
  (interactive (list
                org-brain--vis-entry))

  (let* ((entries
          (org-brain-associates org-brain--vis-entry))
         (child (cond
                 ((equal 1 (length entries)) (car-safe entries))
                 ((not entries) (error (concat (str entry) " has no children")))
                 (t (org-brain-choose-entry "Goto associate: " entries nil t)))))
    (org-brain-visualize-goto child)))

(defun org-brain-visualize-top (&optional entry)
  "Go up the tree to the top"
  (interactive)

  (if entry
      (org-brain-visualize entry))

  (let ((parent t))
    (while parent
      (setq entry (org-brain-entry-at-pt))
      (setq parent (car (or (org-brain-local-parent entry)
                            (org-brain-parents entry))))
      (if parent
          (org-brain-visualize parent)
        (progn
          (goto-char (point-min))
          (message "Arrived at top"))))))


(defun org-brain-recursive-children-flat (entry max-level &optional func)
  "Return a tree of ENTRY and its (grand)children up to MAX-LEVEL.
Apply FUNC to each tree member. FUNC is a function which takes an
entry as the only argument. If FUNC is nil or omitted, get the
raw entry data."
  (cons
   (funcall (or func #'identity) entry)
   (when (> max-level 0)
     (flatten-once
      (mapcar (lambda (x) (org-brain-recursive-children-flat x (1- max-level) func))
              (org-brain-children entry))))))
(defun org-brain-visualize-goto-recursive-children-flat (entry &optional max-level)
  ""
  (interactive (list ;; (org-brain-entry-at-pt)
                org-brain--vis-entry))
  (setq max-level (or max-level 10))
  (let* ((entries
          (-uniq (org-brain-recursive-children-flat org-brain--vis-entry max-level)))
         (child (cond
                 ((equal 1 (length entries)) (car-safe entries))
                 ((not entries) (error (concat (str entry) " has no children")))
                 (t (org-brain-choose-entry "Goto child: " entries nil t)))))
    (org-brain-visualize-goto child)))


(defun org-brain-goto-child-recursively (entry &optional max-level)
  "Goto a child of ENTRY.
If run interactively, get ENTRY from context.
If ALL is nil, choose only between externally linked children."
  (interactive (list (org-brain-entry-at-pt)))
  (setq max-level (or max-level 10))
  (let* ((entries (org-brain-recursive-children-flat entry max-level))
         (child (cond
                 ((equal 1 (length entries)) (car-safe entries))
                 ((not entries) (error (concat entry " has no children")))
                 (t (org-brain-choose-entry "Goto child: " entries nil t)))))
    (org-brain-goto child)))


(defun org-brain-add-entry (title)
  "Add a new entry named TITLE."
  (interactive "sNew entry: ")
  (message "Added new entry: '%s'"
           (org-brain-entry-name (org-brain-get-entry-from-title title)))
  (org-brain-visualize-reset-map title))

(define-key org-brain-visualize-mode-map (kbd "N") 'org-brain-add-entry)

(defun org-brain-visualize-reset-map (entry)
  (interactive)
  
  (with-current-buffer (org-brain-visualize entry)
    (when (eq major-mode 'org-brain-visualize-mode)
      (setq org-brain-visualizing-mind-map nil))
    (revert-buffer)))

(defun pen-fz-org-brain-shortcut-select ()
  (interactive)

  (let ((f (fz pen-org-brain-shortcut-list
               nil nil "pen-fz-org-brain-shortcut-select: ")))
    (if (sor f)
        (call-interactively (str2sym f)))))

(defun pen-fz-org-brain-select ()
  (interactive)

  (let ((f (fz pen-org-brain-list
               nil nil "pen-fz-org-brain-select: ")))
    (if (sor f)
        (call-interactively (str2sym f)))))

(defun org-brain-clear-data-reset (dir-or-name)
  (interactive (list (fz (mapcar 'f-base (glob (f-join org-brains-dir "*")))
                         nil nil "org-brain clear metadata: ")) "D")

  (let ((fp (f-join org-brains-dir dir-or-name ".org-brain-data.el")))
    (f-delete fp f)))

(defun org-brain-edit-metadata (dir-or-name)
  (interactive (list (fz (mapcar 'f-base (glob (f-join org-brains-dir "*")))
                         nil nil "org-brain edit metadata: ")) "D")

  (let ((fp (f-join org-brains-dir dir-or-name ".org-brain-data.el")))
    (f-touch fp)
    (e fp)))

;; j:org-brain-switch-brain

(defun pen-org-brain-switch-brain (dir-or-name)
  (interactive (list (fz (mapcar 'f-base (glob (f-join org-brains-dir "*")))
                         nil nil "switch or make brain: ")) "D")
  (with-current-buffer (switch-to-buffer "*scratch*")

    (let ((default-directory org-brains-dir))
      (if (not (f-directory-p dir-or-name))
          (mkdir-p (f-directory-p dir-or-name))
        ;; (error (concat dir-or-name " is not a directory"))
        )

      (if (not (f-directory-p dir-or-name))
          (mkdir-p dir-or-name))

      (if (not (f-file-p (f-join dir-or-name "index.org")))
          (f-touch (f-join dir-or-name "index.org")))

      ;; (tv (f-realpath dir-or-name))

      (org-brain-switch-brain (f-join org-brains-dir dir-or-name))
      ;; (org-brain-add-entry "index")
      (org-brain-visualize-reset-map "index")))

  ;; (org-brain-update-id-locations)

  ;; (cl-loop for b in
  ;;          (org-brain-files)
  ;;          do
  ;;          (find-file b)
  ;;          (with-current-buffer (current-buffer)
  ;;            (save-buffer)
  ;;            (kill-buffer)))
  )

;; [[brain:agenda/index]]
;; (org-brain-entry-from-text "prayers")
;; (etv (list2str (org-brain--all-targets)))
;; (assoc "prayers" (org-brain--all-targets))
;; (member "prayers" (mapcar 'car (org-brain--all-targets)))
;; (-contains? (mapcar 'car (org-brain--all-targets)) "prayers")
(defun org-brain-entry-from-text (text)
  (interactive (list (read-string-hist "org-brain-entry: ")))
  (pen-org-brain-switch-brain (chomp (cut text :d "/" :f 1)))
  (let* ((name (chomp (cut text :d "/" :f 2)))
         (all-targets (org-brain--all-targets))
         (ii (major-mode-p org-brain-visualize-mode))
         (ensure-dir-is-idified
          (if org-brain--vis-entry
              (idify-org-files-here default-directory)))
         (entry

          (let ((item-names (mapcar 'car all-targets)))
            (comment
             (org-brain-choose-entry "Goto entry: " 'all nil t name))
            (if (member name item-names)

                (if (re-match-p "::" name)
                    (let ((id
                           (cdr (assoc name (org-brain--all-targets)))))
                      (append (s-split "::" name)
                              (list id)))
                  name)
              (org-brain-choose-entry "Goto entry: " 'all nil t name)))))
    (org-brain-visualize entry)))

(defun defswitchbrain (prefix brainname)
  (interactive (list (read-string "new brain prefix: ")
                     (read-string "new brain name: ")))

  (let ((fun (eval `(dff (obsb ,brainname)))))
    (add-to-list 'pen-org-brain-list fun)
    (define-key org-brain-visualize-mode-map (kbd (concat "SPC " (esed "\\(.\\)" "\\1 " prefix))) fun)))

(defun defswitchbrainentry (prefix entry)
  (let ((fun (eval `(dff (obeft ,entry)))))
    (add-to-list 'pen-org-brain-shortcut-list fun)
    (define-key org-brain-visualize-mode-map (kbd (concat "D " (esed "\\(.\\)" "\\1 " prefix))) fun)))

(defun defswitchbrainlocalshortcut (prefix entry)
  (let ((fun (eval `(dff (obvrm ,entry)))))
    (add-to-list 'pen-org-brain-local-shortcut-list fun)
    (define-key org-brain-visualize-mode-map (kbd (concat "I " (esed "\\(.\\)" "\\1 " prefix))) fun)))
(defalias 'dsbls 'defswitchbrainlocalshortcut)

(defun brain-shortcuts () (interactive) (j 'brain-shortcuts))
(define-key org-brain-visualize-mode-map (kbd ".") 'brain-shortcuts)
;; (define-key org-brain-visualize-mode-map (kbd ">") 'brain-shortcuts)
(define-key org-brain-visualize-mode-map (kbd ">") 'pen-fz-org-brain-shortcut-select)
(define-key org-brain-visualize-mode-map (kbd "Z") 'pen-fz-org-brain-select)

(defset brainkeys
  '(
    ;; Prefix Q
    ("b" "billboard")
    ;; exploratory learning
    ("e" "exploratory")
    ("t" "tooling")
    ("c" "national-security")
    ("s" "studies")
    ("gl" "geology")
    ("gg" "geography")
    ("h" "thoughts")
    ;; (define-key org-brain-visualize-mode-map (kbd (concat "Q " (esed "\\(.\\)" "\\1 " "Y"))) nil)
    ("yb" "biocommunication")
    ("yy" "philosophy")
    ("m" "sensorium")
    ("u" "ubuntu")
    ("7" "science-fiction")
    ("r" "reference")
    ("l" "learning")
    ("f" "fungible")
    ("d" "ideation")
    ("o" "open-source-alternatives")
    ("i" "infogetics")
    ;; (define-key org-brain-visualize-mode-map (kbd (concat "Q " (esed "\\(.\\)" "\\1 " "P"))) nil)
    ("c" "clojure")
    ("pc" "clojure")
    ("pp" "python")
    ("pl" "programming-languages")
    ;; (define-key org-brain-visualize-mode-map (kbd (concat "Q " (esed "\\(.\\)" "\\1 " "PL"))) nil)
    ("w" "welfare-organisations")
    ("a" "agenda")))

(cl-loop for tp in brainkeys
      do
      (apply 'defswitchbrain tp))


;; TODO Find a comparator
(never
 (eval
  (cons 'qa
        (flatten-once
         (mapcar
          (lambda (tp)
            (list
             (str2sym (concat "-"
                              ;; get the first letter of the first element
                              (car tp)))
             (cadr tp)))
          (-filter
           (lambda (tp)
             (equal 1 (length (car tp))))
           brainkeys))))))


(defun qa-select-brain ()
  (interactive)

  (let ((br
         (pen-qa
          -b "billboard"
          -i "ideation"
          )))
    (pen-org-brain-switch-brain br)))

;; These shortcuts should really just be fuzzy searchable. They are lol
;; Prefix D
;; (defswitchbrainentry "N" "neuralink/index")
;; (defswitchbrainentry "I" "infogetics/index")
;; (defswitchbrainentry "T" "infogetics/text->text")
(defswitchbrainentry "A" "agenda/agenda")

;; Prefix I
;; (dsbls "i" "index")
(dsbls "I" "index")
(dsbls "B" "fungible")
(dsbls "N" "NLP")
(dsbls "H" "haskell")
(dsbls "K" "haskell")
(dsbls "T" "nlp tasks")
(dsbls "F" "Information Retrieval")
(dsbls "P" "Programming")
(dsbls "E" "emacs")
;; (dsbls "U" "ubuntu")
(dsbls "A" "infrastructure")
(dsbls "O" "studies")
(dsbls "G" "organisations")
(dsbls "D" "nlp disciplines")
(dsbls "M" "models")
(dsbls "C" "Coding tests")

;; (defun org-brain-visualize-around-advice (proc &rest args)
;;   (when (eq major-mode 'org-brain-visualize-mode)
;;     (setq org-brain-visualizing-mind-map nil))

;;   (let ((res (apply proc args)))
;;     res))
;; (advice-add 'org-brain-visualize :around #'org-brain-visualize-around-advice)
;; (advice-remove 'org-brain-visualize #'org-brain-visualize-around-advice)

;; This actually *doesn't* turn the headings into local children
;; So it's pretty useless
(defun org-brain-visualize-this-org ()
  (interactive)

  (let* ((fp (get-path))
         (bn (basename fp))
         (dn (f-dirname fp))
         (ext (file-name-extension bn))
         (mant (file-name-sans-extension bn))
         (slug (slugify (concat dn "/" mant))))

    (pen-sn (pen-cmd "ln" "-s" fp "--" (concat slug ".org")) nil org-brains-dir)
    (org-brain-visualize slug)))


(advice-add 'org-brain-get-id :around #'ignore-errors-around-advice)

(defun idify-org-files-here (dirpath)
  (interactive (list (read-directory-name "idify-org-files dir: ")))
  (cl-loop for fp in
        (-filter 'sor (pen-str2list (pen-snc (pen-cmd "find" dirpath "-type" "f" "-name" "*.org"))))
        do
        (idify-org-file fp t)))

(defun unidify-org-files-here (dirpath)
  (interactive (list (read-directory-name "unidify-org-files dir: ")))
  (cl-loop for fp in
        (-filter 'sor (pen-str2list (pen-snc (pen-cmd "find" dirpath "-type" "f" "-name" "*.org"))))
        do
        (unidify-org-file fp t)))

(defun idify-org-file (path &optional save)
  "Add IDs to all the headers in an org file"
  (interactive (list (read-file-name "org file:" nil nil t
                                     (if
                                         (and (ignore-errors (file-exists-p (buffer-file-name)))

                                              (string-match "\\.org$" (buffer-file-name)))
                                         (buffer-file-name))
                                     (lambda (fp)
                                       (and (file-exists-p fp)

                                            (string-match "\\.org$" fp))))))

  (if (string-match "\\.org$" path)
      (with-current-buffer
          (find-file path)
        ;; (beginning-of-buffer)
        ;; (org-map-entries 'org-id-get-create "LEVEL=1")
        (org-map-entries 'org-brain-get-id t)
        (if save
            (save-buffer)))))

(defun org-id-remove-entry (&optional do-not-update-map)
"Remove/delete the ID entry and update the databases.
Update the `org-id-locations' global hash-table, and update the
`org-id-locations-file'.  `org-id-track-globally' must be `t`."
(interactive)
  (save-excursion
    (org-back-to-heading t)
    (when (org-entry-delete (point) "ID")
      (unless do-not-update-map
        (org-id-update-id-locations nil 'silent)))))

(defun unidify-org-file (path &optional save)
  "Remove IDs from all the headers in an org file"
  (interactive (list (read-file-name "org file:" nil nil t
                                     (if
                                         (and (ignore-errors (file-exists-p (buffer-file-name)))

                                              (string-match "\\.org$" (buffer-file-name)))
                                         (buffer-file-name))
                                     (lambda (fp)
                                       (and (file-exists-p fp)

                                            (string-match "\\.org$" fp))))))

  (if (string-match "\\.org$" path)
      (with-current-buffer
          (find-file path)
        (org-map-entries (lambda () (org-id-remove-entry t)) t)
        (org-id-update-id-locations nil 'silent)
        (if save
            (save-buffer)))))

(defun org-brain-name-from-list-maybe (l)
  (if (and (listp l)
           (> (length l) 1))
      (second l)
    l))

(defun org-brain-remove-irrelevant-names-from-path (path)
  (-filter
   (lambda (e)
     (not (or
           (string-equal "infogetics" e)
           (string-equal "fungible" e))))
   (mapcar (lambda (e)
             (if (string-equal "infogetics" e)
                 "deep learning"
               e))
           path)))

(defun org-brain-parent-name ()
  (pen-snc "pen-str join"
    (pen-list2str
           (org-brain-remove-irrelevant-names-from-path
            (mapcar
             'org-brain-name-from-list-maybe
             (org-brain-parents org-brain--vis-entry))))))

(defun org-brain-current-name (&optional unslugify)
  (let ((cn
         (car
          (org-brain-remove-irrelevant-names-from-path
           (mapcar
            'org-brain-name-from-list-maybe
            (list org-brain--vis-entry))))))
    (if unslugify
        (unslugify cn)
      cn)))

(defun org-brain-current-topic (&optional for-external-searching)
  (interactive)
  (let ((cname (org-brain-current-name))
        (pname (org-brain-parent-name))
        (path (mapcar 'org-brain-name-from-list-maybe (append (org-brain-parents org-brain--vis-entry) (list org-brain--vis-entry))))
        (topic))

    (setq topic
          (cond
           ((org-brain-at-child-of-index) cname)
           ((org-brain-at-top-index) "general knowledge")
           (t "general knowledge")))

    (setq path
          (let ((l (if for-external-searching
                       (org-brain-remove-irrelevant-names-from-path path)
                     path)))
            (if (org-brain-is-index-name (car l))
                (-drop 1 l)
              l)))

    (let ((topic (chomp (apply 'pen-cmd path))))
      (if (not (sor topic))
          (setq topic "general knowledge"))

      (if (interactive-p)
          (pen-etv topic)
        topic))))

(defun org-brain-google-here (query)
  (interactive (list (read-string-hist
                      "egr: "
                      (if (sor (org-brain-current-topic t))
                          (concat
                           (org-brain-current-topic t)
                           " ")
                        (org-brain-current-topic t)))))
  (if (not (interactive-p))
      (setq query (concat query " " (org-brain-current-topic t))))
  (egr query))

(defun org-brain-pf-topic (&optional short)
  "Topic used for pen functions"
  (let ((cn (org-brain-current-name t)))
    (if (and (org-brain-is-index-name cn)
             (not (sor (org-brain-parent-name))))
        (if (org-brain-is-index-name (org-brain-current-brain))
            "general knowledge"
          (org-brain-current-brain))
      (let ((p (org-brain-parent-name)))
        (if (and (sor p)
                 (not short)
                 (not (org-brain-is-index-name p)))
            (concat cn " (" cn " is a subtopic of " p ")")
          cn)))))

(defun org-brain-existing-subtopics ()
  (mapcar (lambda (s) (s-replace-regexp ".*::" "" s))
          (mapcar 'org-brain-entry-name
                  (org-brain-list-child-nodes))))

(defun org-brain-existing-subtopics-stringlist (&optional add-dash)
  ;; output a multiline dashed string
  (pen-awk1
   (pen-list2str
    (if add-dash
        (mapcar
         (lambda (s) (concat "- " s))
         (org-brain-existing-subtopics))
      (org-brain-existing-subtopics)))))

;; Also, take into consideration existing subtopic-candidates
(defun org-brain-suggest-subtopics (&optional update do-not-incorportate-existing suggest-full-list edit-full-list)
  "
update will update the cache
do-not-incorportate-existing will not incorporate existing subtopics into the prompt, so they do not influence suggestions
edit-full-list allows you to edit the list before proceeding
suggest-full-list will ask if you want to add the entire list as subtopics to the current entry
"
  (interactive)

  (let ((inhibit-quit t))
    (unless (with-local-quit
              (progn
                (pen-qa
                 -u (setq update t)
                 -n (setq do-not-incorporate-existing t)
                 -i (setq do-not-incorporate-existing nil)
                 -e (setq edit-full-list t)
                 -f (setq suggest-full-list t)
                 -F (setq suggest-full-list t update t))

                (message "Using pen.el to suggest subtopics...")

                (let ((subtopic-candidates
                       ;; (pen-single-batch (pf-keyword-extraction/1 (org-brain-current-topic t)))
                       (let ((pen-sh-update (or pen-sh-update
                                            update
                                            (eq (prefix-numeric-value current-prefix-arg) 4)))
                             (existing-subtopics-string (if do-not-incorportate-existing
                                                            ""
                                                          (org-brain-existing-subtopics-stringlist t))))

                         ;; These evals are necessary. Otherwise, emacs will prompt when the function is defined
                         (let ((s
                                (car
                                 (eval
                                  `(pen-single-batch
                                    (pf-subtopic-generation/2
                                     ,(pen-topic)
                                     ,existing-subtopics-string))))))
                           (if (not (sor s))
                               (progn
                                 (message "Empty generation 1/3. Trying again.")
                                 (setq
                                  s
                                  (car
                                   (eval
                                    `(upd (pen-single-batch
                                           (pf-subtopic-generation/2
                                            ,(pen-topic)
                                            ,existing-subtopics-string))))))
                                 (if (not (sor s))
                                     (progn
                                       (message "Empty generation 2/3. Trying again.")
                                       (setq
                                        s
                                        (car
                                         (eval
                                          `(upd (pen-single-batch
                                                 (pf-subtopic-generation/2
                                                  ,(pen-topic)
                                                  ,existing-subtopics-string))))))
                                       (if (not (sor s))
                                           (progn
                                             (message "Empty generation 3/3. Giving up.")
                                             (error "Empty generation 3/3. Giving up."))
                                         s))
                                   s)
                                 s)
                             s)))))

                  (setq subtopic-candidates
                        (-filter-not-empty-string
                         (-uniq-u
                          (pen-str2list
                           (concat
                            (pen-awk1 subtopic-candidates)
                            (org-brain-existing-subtopics-stringlist)
                            (org-brain-existing-subtopics-stringlist))))))

                  ;; (tv subtopic-candidates)

                  ;; The prompt does "- " removal on its own now
                  ;; (setq subtopic-candidates
                  ;;       (pen-str2list
                  ;;        (pen-cl-sn
                  ;;         "sed 's/^- //'"
                  ;;         :stdin
                  ;;         (chomp
                  ;;          (pen-snc
                  ;;           (pen-cmd "scrape" "^- [a-zA-Z -]+$")
                  ;;           (concat "- " subtopic-candidates))) :chomp t)))

                  ;; (ns current-prefix-arg)

                  (if (interactive-p)
                      (progn
                        (let ((subtopic-selected
                               (try
                                (cond
                                 (edit-full-list
                                  (nbfs (pen-list2str subtopic-candidates)))
                                 (suggest-full-list
                                  (let ((b (nbfs (pen-list2str subtopic-candidates))))
                                    (with-current-buffer b
                                      (let ((r (if (yn "Add all?")
                                                   subtopic-candidates)))
                                        (kill-buffer b)
                                        r))))
                                 (t
                                  ;; Select one, do not refresh cache
                                  (list (fz subtopic-candidates)))))))

                          (if subtopic-selected
                              (cl-loop for st in subtopic-selected do
                                       (org-brain-add-child-headline org-brain--vis-entry st)))))
                    subtopic-candidates)))
              t)
      (progn
        (message "Cancelled")
        (setq quit-flag nil)))))

;; This breaks interactive, and it doesn't work anyway
;; (advice-add 'org-brain-suggest-subtopics :around #'cgify-around-advice)
;; (advice-remove 'org-brain-suggest-subtopics #'cgify-around-advice)

;; org-brain-add-child-headline


;; Abstract this out so I can use the pen functions on anything
(defun org-brain-asktutor (question)
  (interactive (list (read-string-hist (concat "asktutor about " (pen-topic) ": "))))
  (let ((topic (org-brain-current-topic)))

    (let ((answer
           (pen-snc
            "pen-pretty-paragraph"
            (car
             (eval
              `(pen-single-batch
                (pf-generic-tutor-for-any-topic/2
                 ,topic
                 ;; ,cname
                 ;; ,pname
                 ,question)))))))
      (if (interactive-p)
          (pen-etv answer)
        answer))))

(defun pen-org-brain-goto-header ()
  (interactive)
  (try
   (progn
     ;; This is if you clicked on a brain local child
     (org-back-to-heading)
     (org-end-of-meta-data t))
   (progn
     (call-interactively 'beginning-of-buffer)
     (if (re-match-p "^\\*" (buffer-string))
         (progn (call-interactively 'org-next-visible-heading)
                (previous-line)))
     (call-interactively 'mwim-end-of-line-or-code)
     (message "Couldn't find heading")
     (end-of-buffer)
     (newline))))

(defun pen-org-brain-goto-current ()
  (interactive)
  (progn-continue-failures
   (call-interactively 'org-brain-goto-current)
   (call-interactively 'pen-org-brain-goto-header)))

(define-key org-brain-visualize-mode-map (kbd "RET") 'pen-org-brain-goto-current)

(defun pen-org-brain-add-child (entry children verbose)
  (interactive (list (if current-prefix-arg
                         (car (org-brain-button-at-point))
                       (org-brain-entry-at-pt t))
                     (org-brain-choose-entries "Add child: " 'all)
                     t))
  (if children
      (progn
        (org-brain-add-child entry children verbose)
        ;; (tv (pps children))
        (org-brain-visualize (car (last children))))))


(defun org-brain-describe-topic ()
  (interactive)

  (require 'pen)
  (let* ((p (sor (org-brain-parent-name)))
         (pretext)
         (question (if (and
                        p "brain-description\"\""
                        (not (org-brain-at-child-of-index))
                        (not (org-brain-is-index-name p)))
                       (concat "Could you please explain what is meant by " (pen-topic t) " in the context of " p " and why it is important?")
                     (concat "Could you please explain what is meant by " (pen-topic t) " and why it is important?")))
         (final-question
          (if (sor pretext)
              (concat pretext " " question)
            question)))

    (let ((description
           ;; (eval `(upd (org-brain-asktutor ,final-question)))
           (org-brain-asktutor final-question)))
      (if (sor description)
          (progn
            (let ((cb (current-buffer)))
              (pen-org-brain-goto-current)
              (let ((block-name (concat (org-brain-current-name) "-description")))
                (if (not (org-babel-find-named-block block-name))
                    (progn
                      (insert (pen-sn (concat (pen-cmd "pen-org-template-gen" "brain-description" block-name) " | awk 1") description))
                      (call-interactively 'save-buffer)
                      (call-interactively 'kill-buffer-and-window))))
              (with-current-buffer cb
                (revert-buffer))))))))

(defun org-brain-show-topic ()
  (interactive)
  (call-interactively 'pen-topic))

(defun org-brain-current-entry ()
  org-brain--vis-entry)

(defun org-brain-headline-to-file-this ()
  (interactive)
  (if (listp org-brain--vis-entry)
      (org-brain-headline-to-file org-brain--vis-entry)))

(defun org-brain-current-depth ()
  (org-brain-tree-depth (org-brain-recursive-parents org-brain--vis-entry 100)))

(defun org-brain-go-index ()
  (interactive)
  (obsb "billboard"))

(defun org-brain-at-top ()
  (eq 1 (org-brain-current-depth)))

(defun org-brain-is-index-name (s)
  (or (string-equal s "index")
      (string-equal s "infogetics")
      (string-equal s "billboard")
      (string-equal s "exploratory")
      (string-equal s "reference")))

(defun org-brain-at-child-of-index ()
  (let ((p (sor (org-brain-parent-name))))
    (and (org-brain-is-index-name p)
         (eq 2 (org-brain-current-depth)))))

(defun org-brain-at-top-index ()
  (let ((c (sor (org-brain-current-name))))
    (and (org-brain-is-index-name c)
         (eq 1 (org-brain-current-depth)))))

(defun org-brain-visualize (entry &optional nofocus nohistory wander)
  "View a concept map with ENTRY at the center.

When run interactively, prompt for ENTRY and suggest
`org-brain-entry-at-pt'.  By default, the choices presented is
determined by `org-brain-visualize-default-choices': 'all will
show all entries, 'files will only show file entries and 'root
will only show files in the root of `org-brain-path'.

You can override `org-brain-visualize-default-choices':
  `\\[universal-argument]' will use 'all.
  `\\[universal-argument] \\[universal-argument]' will use 'files.
  `\\[universal-argument] \\[universal-argument] \\[universal-argument]' will use 'root.

Unless NOFOCUS is non-nil, the `org-brain-visualize' buffer will gain focus.
Unless NOHISTORY is non-nil, add the entry to `org-brain--vis-history'.
Setting NOFOCUS to t implies also having NOHISTORY as t.
Unless WANDER is t, `org-brain-stop-wandering' will be run."
  (interactive
   (progn
     (org-brain-maybe-switch-brain)
     (let ((choices (cond ((equal current-prefix-arg '(4)) 'all)
                          ((equal current-prefix-arg '(16)) 'files)
                          ((equal current-prefix-arg '(64)) 'root)
                          (t org-brain-visualize-default-choices)))
           (def-choice (unless (eq major-mode 'org-brain-visualize-mode)
                         (ignore-errors (org-brain-entry-name (org-brain-entry-at-pt))))))
       (org-brain-stop-wandering)
       (list
        (org-brain-choose-entry
         "Entry: "
         (cond ((equal choices 'all)
                'all)
               ((equal choices 'files)
                (org-brain-files t))
               ((equal choices 'root)
                (make-directory org-brain-path t)
                (mapcar #'org-brain-path-entry-name
                        (directory-files org-brain-path t (format "\\.%s$" org-brain-files-extension)))))
         nil nil def-choice)))))
  (unless wander (org-brain-stop-wandering))
  (with-current-buffer (get-buffer-create "*org-brain*")
    (setq-local indent-tabs-mode nil)
    (read-only-mode 1)
    (setq-local default-directory (file-name-directory (org-brain-entry-path entry)))
    (org-brain-maybe-switch-brain)
    (unless (eq org-brain--vis-entry entry)
      (setq org-brain--vis-entry entry)
      (setq org-brain-mind-map-parent-level (default-value 'org-brain-mind-map-parent-level))
      (setq org-brain-mind-map-child-level (default-value 'org-brain-mind-map-child-level)))
    (setq org-brain--vis-entry-keywords (when (org-brain-filep entry)
                                          (org-brain-keywords entry)))
    (let ((inhibit-read-only t)
          (entry-pos))
      (delete-region (point-min) (point-max))
      (org-brain--vis-brain)
      (org-brain--vis-pinned)
      (org-brain--vis-selected)
      (when (not nohistory)
        (setq org-brain--vis-history
              (seq-filter (lambda (elt) (not (equal elt entry))) org-brain--vis-history))
        (setq org-brain--vis-history (seq-take org-brain--vis-history 15))
        (push entry org-brain--vis-history))
      (when org-brain-show-history (org-brain--vis-history))
      (if org-brain-visualizing-mind-map
          (setq entry-pos (org-brain-mind-map org-brain--vis-entry org-brain-mind-map-parent-level org-brain-mind-map-child-level))
        (setq-local org-brain--visualize-header-end-pos (point))
        (insert "\n\n")
        (org-brain--vis-parents-siblings entry)
        ;; Insert entry title
        (let ((title (org-brain-vis-title entry)))
          (let ((half-title-length (/ (string-width title) 2)))
            (if (>= half-title-length (current-column))
                (delete-char (- (current-column)))
              (ignore-errors (delete-char (- half-title-length)))))
          (setq entry-pos (point))
          (insert (propertize title
                              'face (org-brain-display-face entry 'org-brain-title)
                              'aa2u-text t))
          (org-brain--vis-friends entry)
          (org-brain--vis-children entry)))
      (when (and org-brain-show-resources)
        (org-brain--vis-resources (org-brain-resources entry)))
      (if org-brain-show-text
          (org-brain--vis-text entry)
        (run-hooks 'org-brain-after-visualize-hook))
      (unless (eq major-mode 'org-brain-visualize-mode)
        (org-brain-visualize-mode))
      (goto-char entry-pos)
      (set-buffer-modified-p nil))
    (unless nofocus
      (when org-brain--visualize-follow
        (org-brain-goto-current)
        (run-hooks 'org-brain-visualize-follow-hook))
      (if (or org-brain--visualize-follow org-brain-open-same-window)
          (pop-to-buffer "*org-brain*")
        (pop-to-buffer-same-window "*org-brain*")))))

(defun org-brain-current-brain ()
  (f-base org-brain-path))

(defun org-brain--vis-brain ()
  "Insert pinned entries.
Helper function for `org-brain-visualize'."
  ;; (insert (concat "BRAIN: " (mnm org-brain-path)))
  (insert (concat "BRAIN: " (org-brain-current-brain)))
  (insert "\n"))

(defun org-brain-get-path-for-child-name (child-name &optional semantic-path)
  "This gets the path for the entry given the name of a child, current brain and current entry."
  (interactive)
  (let ((p (if semantic-path
               (org-brain-pf-topic)
             ;; (org-brain-current-topic t)
             (concat
              "[[brain:"
              (org-brain-current-brain)
              "/"
              child-name
              "]]"))))
    (if (interactive-p)
        (xc p)
      p)))

;; This is more accurate than org-brain-get-path-for-child-name
(defun org-brain-get-path-for-entry (entry &optional semantic-path)
  "This gets the path for the entry given, current brain and current entry."
  (interactive)
  (let ((p (if semantic-path
               (org-brain-pf-topic)
             ;; (org-brain-current-topic t)
             (concat
              "[[brain:"
              (org-brain-current-brain)
              "/"
              (org-brain-entry-name entry)
              "]]"))))
    (if (interactive-p)
        (xc p)
      p)))

(defun org-brain-toggle-maybefictional (entry)
  "ENTRY gets a new NICKNAME.
If run interactively use `org-brain-entry-at-pt' and prompt for NICKNAME."
  (interactive (list (org-brain-entry-at-pt)))
  (if (org-brain-filep entry)
      (org-with-point-at (org-brain-entry-marker entry)
        (goto-char (point-min))
        (if (re-search-forward "^#\\+MAYBE_FICTIONAL:.*$" nil t)
            (insert (concat " t"))
          (insert "#+MAYBE_FICTIONAL: t\n"))
        (save-buffer))
    (org-entry-add-to-multivalued-property
     (org-brain-entry-marker entry) "MAYBE_FICTIONAL" nickname)
    (org-save-all-org-buffers)))

(defun org-brain-show-recursive-children ()
  (interactive)
  (nbfs (pp-to-string (org-brain-recursive-children (org-brain-current-entry) 100)) nil 'emacs-lisp-mode))

(defun org-brain-show-recursive-children-names ()
  (interactive)
  (nbfs (pp-to-string (org-brain-recursive-children (org-brain-current-entry) 100 'org-brain-entry-name)) nil 'emacs-lisp-mode))

(defun pp-org-brain-tree (tre &optional parent)
  (interactive (list (org-brain-recursive-children
                      (org-brain-current-entry) 100
                      (lambda (e)
                        (cons (org-brain-entry-name e)
                              (let* ((f (org-brain-friends e)))
                                (if f
                                    (let ((ht (make-hash-table)))
                                      (puthash :friends f ht)
                                      ht))))))))

  (nbfs (pp-to-string tre) nil 'emacs-lisp-mode))

(defun org-brain-recursive-children-visited (entry max-level visited &optional func)
  "Return a tree of ENTRY and its (grand)children up to MAX-LEVEL.
Apply FUNC to each tree member. FUNC is a function which takes an
entry as the only argument. If FUNC is nil or omitted, get the
raw entry data.
Also stop descending if a node has been visited before.
"
  (let ((en (org-brain-entry-name entry)))
    (if (not (and (ht-contains? org-brain-visited-ht (sxhash-equal en))))
        (cons (funcall (or func #'identity) entry)
              (when (> max-level 0)
                (ht-set org-brain-visited-ht (sxhash-equal en) t)
                (mapcar (lambda (x) (org-brain-recursive-children-visited x (1- max-level) visited func))
                        (org-brain-children entry)))))))

(defvar org-brain-visited-ht)

(defun org-brain-recursive-associates-visited (entry max-level &optional func)
  "Return a tree of ENTRY and its (grand)associates up to MAX-LEVEL.
Apply FUNC to each tree member. FUNC is a function which takes an
entry as the only argument. If FUNC is nil or omitted, get the
raw entry data.
Also stop descending if a node has been visited before.
"
  (let ((en (org-brain-entry-name entry)))
    (if (not (and (ht-contains? org-brain-visited-ht (sxhash-equal en))))
        (cons (funcall (or func #'identity) entry)
              (when (> max-level 0)
                (ht-set org-brain-visited-ht (sxhash-equal en) t)
                (mapcar (lambda (x) (org-brain-recursive-associates-visited x (1- max-level) func))
                        (org-brain-associates entry)))))))

(defun org-brain-to-dot-associates (&optional depth)
  (interactive (list
                (pen-qa
                 -a 0 -s 1 -d 2 -f 3 -g 4
                 -r (string-to-number (read-string-hist "depth: " "5" nil 5)))))

  (if (not depth)
      (setq depth 5))

  (let* ((recurfun 'org-brain-recursive-associates-visited)
         (tre
          (-flatten
           (progn
             (setq org-brain-visited-ht (make-hash-table))
             (funcall recurfun
                      (org-brain-current-entry) depth
                      (lambda (e)
                        (let* ((n (org-brain-entry-name e))
                               (fs (mapcar 'org-brain-entry-name (org-brain-friends e)))
                               (cs (mapcar 'org-brain-entry-name (org-brain-children e))))
                          (list
                           (if fs
                               (cl-loop for f in fs
                                     collect
                                     (list (concat (e/q n) " -> " (e/q f))
                                           (concat (e/q f) " -> " (e/q n))))
                             ;; "FRIENDS"
                             )
                           (if cs
                               (cl-loop for c in cs
                                     collect
                                     (concat (e/q n) " -> " (e/q c)))
                             ;; "CHILDREN"
                             )))))))))

    (nbfs (pen-snc "uniqnosort" (pen-list2str tre)) nil 'graphviz-dot-mode)))

(defun org-brain-to-dot-children (&optional depth)
  (interactive (list (string-to-number (read-string-hist "depth: " "5" nil 5))))

  (if (not depth)
      (setq depth 5))

  (let* ((recurfun 'org-brain-recursive-children-visited)
         (tre
          (-flatten
           (progn
             (setq org-brain-visited-ht (make-hash-table))
             (funcall recurfun
                      (org-brain-current-entry) depth
                      (lambda (e)
                        (let* ((n (org-brain-entry-name e))
                               (cs (mapcar 'org-brain-entry-name (org-brain-children e))))
                          (list
                           ;; (concat "[" n "]")
                           (if cs
                               (cl-loop for c in cs
                                     collect
                                     (concat (e/q n) " -> " (e/q c)))
                             ;; "CHILDREN"
                             )))
                        ;; (list (org-brain-entry-name e)
                        ;;       (org-brain-friends e))
                        ))))))

    (nbfs (pen-snc "uniqnosort" (pen-list2str tre)) nil 'graphviz-dot-mode)))

(defun select-brain-paths-recursive (&optional max-level)
  (interactive)

  (let* ((all-brain-paths
          (pen-snc "pen-list-brain-targets")
          ;; (save-window-excursion
          ;;   (save-excursion
          ;;     (-flatten
          ;;      (cl-loop for dir in (f-directories org-brains-dir)
          ;;               collect
                        
                        
          ;;               (let* ((org-brain-path dir)
          ;;                      (bn (f-basename dir)))
          ;;                 (pen-org-brain-switch-brain org-brain-path)

          ;;                 (mapcar
          ;;                  (lambda (e) (concat bn "/" e))
          ;;                  (mapcar 'car (org-brain--all-targets)))
          ;;                 ;; (mapcar 'org-brain-get-path-for-entry (-uniq (org-brain-recursive-children-flat org-brain--vis-entry (or max-level 10))))
                                  
          ;;                 ;; (cl-loop for child in
          ;;                 ;;          (-uniq (org-brain-recursive-children-flat org-brain--vis-entry (or max-level 10)))
          ;;                 ;;          collect
          ;;                 ;;          (progn
          ;;                 ;;            (org-brain-visualize-goto)
          ;;                 ;;            (org-brain-get-path-for-entry org-brain--vis-entry)))
                                  
          ;;                 ;; org-brain-path
          ;;                 )))))
          )
         ;; (tidied-brain-paths
         ;;  (snc "sed -e 's/[^:]*://' -e 's/]]$//'" (list2str all-brain-paths)))
         (sel
          ;; (fz tidied-brain-paths)
          (fz all-brain-paths nil nil "org-brain: "))
         (link-string (concat "[[brain:" sel "]]")))
    (if (sor sel)
        (org-link-open-from-string link-string))))

;; (defun uniqify-buffer-around-advice (proc &rest args)
;;   (let ((res (uniqify-buffer (apply proc args))))
;;     res))
;; (advice-add 'org-brain-visualize :around #'uniqify-buffer-around-advice)
;; (advice-remove 'org-brain-visualize #'uniqify-buffer-around-advice)

(advice-add 'org-brain-switch-brain :around #'shut-up-around-advice)

;; From org-brain
;; (switch-to-marker (org-brain-entry-marker (org-brain-current-entry)))
(defun switch-to-marker (m)
  (let ((buf  (marker-buffer m)))
    (switch-to-buffer buf)(goto-char m)))

;; ocif -today tm-unbuffer pool pen-e -ic view-agenda | cat
;; tm -uin -w -sout -vipe nw -d -fargs ub -E "pool pen-e -ic view-agenda | cat" | pavs
(defun agenda-string (&optional filter)
  (interactive)
  (let ((agenda-string (snc (cmd "agenda-string" filter))))
    (if (interactive-p)
        (nbfs agenda-string)
      agenda-string)))

;; (org-brain-text (org-brain-current-entry))
(defun org-brain-text (entry &optional all-data)
  "Get the text of ENTRY as string.
Only get the body text, unless ALL-DATA is t."
  (when-let ((entry-text
              (if (org-brain-filep entry)
                  ;; File entry
                  (with-temp-buffer
                    (ignore-errors (insert-file-contents (org-brain-entry-path entry)))
                    (apply #'buffer-substring-no-properties
                           (org-brain-text-positions entry all-data)))
                ;; Headline entry
                (org-with-point-at (org-brain-entry-marker entry)
                  (apply #'buffer-substring-no-properties
                         (org-brain-text-positions entry all-data))))))
    (if all-data
        (org-remove-indentation entry-text)
      (with-temp-buffer
        (if (org-agenda-file-p (org-brain-entry-path (org-brain-current-entry)))
            (let ((title (org-brain-vis-title org-brain--vis-entry)))
              ;; (insert (snc (cmd "grep" "-C" "3" (org-brain-vis-title org-brain--vis-entry))
              ;;              (agenda-string)))
              ;; (insert (org-brain-vis-title org-brain--vis-entry))
              (if (not (string-equal "index" title))
                  (insert
                   (--> (agenda-string (s-replace "…" "" title))
                        ;; Make the tags, which were justified on the right
                        ;; to hug the text to the left
                        (s-replace-regexp "\s\+\\(:[^ ]\+:\\)" " \t\\1" it))))))
        (insert (org-remove-indentation entry-text))
        (goto-char (org-brain-first-headline-position))
        (if (re-search-backward org-brain-resources-start-re nil t)
            (progn
              (end-of-line)
              (re-search-forward org-drawer-regexp nil t))
          (goto-char (point-min)))
        (buffer-substring (point) (point-max))))))


(define-key org-brain-visualize-mode-map (kbd "C-c C-d") 'org-brain-to-dot-associates)
(define-key org-brain-visualize-mode-map (kbd "R") 'org-brain-rename-file)

(define-key org-brain-visualize-mode-map (kbd "t") 'org-brain-visualize-top)
(define-key org-brain-visualize-mode-map (kbd "O") 'org-brain-goto-current)
(define-key org-brain-visualize-mode-map (kbd "o") 'org-brain-visualize-goto)
(define-key org-brain-visualize-mode-map (kbd "y") 'org-brain-goto-child)
(define-key org-brain-visualize-mode-map (kbd "i") (dff (obvrm "index")))
(define-key org-brain-visualize-mode-map (kbd "r") 'org-brain-visualize-goto-recursive-children-flat)
(define-key org-brain-visualize-mode-map (kbd "j") 'org-brain-visualize-goto-associate)
(define-key org-brain-visualize-mode-map (kbd "H") 'org-brain-visualize-goto-associate)
(define-key org-brain-visualize-mode-map (kbd "k") 'org-brain-toggle-maybefictional)
(define-key org-brain-visualize-mode-map (kbd "Y") 'pen-org-brain-switch-brain)

(define-key pen-map (kbd "H-q") 'pen-org-brain-switch-brain)
(define-key pen-map (kbd "H-Q") 'pen-fz-org-brain-shortcut-select)
(define-key org-brain-visualize-mode-map (kbd "c") 'pen-org-brain-add-child)

(define-key org-brain-visualize-mode-map (kbd "=") #'org-brain-visualize-add-grandchild)

(define-key org-brain-visualize-mode-map (kbd "w") 'get-path)
(define-key org-brain-visualize-mode-map (kbd "H-w") 'get-path)

(define-key org-brain-visualize-mode-map (kbd "^") 'org-brain-visualize-parent)
(define-key org-brain-visualize-mode-map (kbd "u") 'org-brain-visualize-parent)

(define-key org-brain-visualize-mode-map (kbd "i") 'pen-org-brain-goto-current)

(define-key org-brain-visualize-mode-map (kbd "M-TAB") 'org-brain-suggest-subtopics)
(define-key org-brain-visualize-mode-map (kbd "<M-tab>") 'org-brain-suggest-subtopics)

(define-key org-brain-visualize-mode-map (kbd "C-c C-c") #'org-ctrl-c-ctrl-c)
(define-key org-brain-visualize-mode-map (kbd "C-c C-o") 'org-open-at-point)

(define-key global-map (kbd "C-c r") 'select-brain-paths-recursive)

(define-key global-map (kbd "C-c M-a") 'dff-obeft-agenda-agenda-)


;; How can I make extra syntax highlighting for the org-brain visualizer
(defset org-brain-visualize-highlights
        ;; '(("Sin\\|Cos\\|Sum" . 'font-lock-function-name-face)
        ;;   ("Pi\\|Infinity" . 'font-lock-constant-face))

        
        '(("TODAY" . 'font-lock-constant-face)
          ("TODO" . 'org-todo)))

(defun set-org-brain-visualize-highlights ()
  (setq font-lock-defaults '(org-brain-visualize-highlights))
  ;; j:font-lock-defaults
  ;; generates:
  ;; j:font-lock-keywords

  (save-excursion
    (goto-char (point-min))
    (search-forward "--- Entry -")
    (beginning-of-line)
    (let ((m (point))
          (p (point-max)))
      (font-lock-fontify-region m p)))
  ;; (font-lock-fontify-region)
  ;; (font-lock-update)
  )

;; (add-hook 'org-brain-after-visualize-hook 'set-org-brain-visualize-highlights)
;; (remove-hook 'org-brain-after-visualize-hook 'set-org-brain-visualize-highlights)
(add-hook 'org-brain-visualize-text-hook 'set-org-brain-visualize-highlights)

(defun around-advice-buffer-erase-trailing-whitespace-advice (proc &rest args)
  (let ((res (apply proc args)))
    (buffer-erase-trailing-whitespace)
    res))
(advice-add 'org-brain-visualize :around #'around-advice-buffer-erase-trailing-whitespace-advice)
;; (advice-remove 'org-brain-visualize #'around-advice-buffer-erase-trailing-whitespace-advice)

(defvar org-brain-included-states '()
  "Header states which are allowed. If not set, then all are allowed.")

(defvar org-brain-excluded-states '()
  "Header states which exclude. If not set then none are excluded.")

;; For example, if I want to display a subtree in org-brain:
;; (setq org-brain-included-tags '(thanksgiving))
(defvar org-brain-included-tags '()
  "Header tags which exclude. If not set then none are excluded.")

(defvar org-brain-excluded-tags '()
  "Header tags which exclude. If not set then none are excluded.")

(comment
 (setq org-brain-included-states '("TODO")))
(setq org-brain-excluded-states '("DONE" "DISCARD"))

(defun org-brain-entry-at-point-excludedp ()
  "Return t if the entry at point is tagged as being excluded from org-brain."

  ;; (if (>= (prefix-numeric-value current-prefix-arg) 4))
  (or
   (and
    org-brain-excluded-states
    (member (str (org-get-todo-state)) org-brain-excluded-states))
   (and
    org-brain-included-states
    (not (member (str (org-get-todo-state)) org-brain-included-states)))

   (let ((tags (org-get-tags)))
     (or (member org-brain-exclude-tree-tag tags)
         (and (member org-brain-exclude-children-tag tags)
              (not (member org-brain-exclude-children-tag
                           (org-get-tags nil t))))))))

(defun org-brain-goto-child (entry &optional all)
  "Goto a child of ENTRY.
If run interactively, get ENTRY from context.
If ALL is nil, choose only between externally linked children."
  (interactive (list (org-brain-entry-at-pt)))
  (let* ((entries (if all (org-brain-children entry)
                    (org-brain--linked-property-entries
                     entry org-brain-children-property-name)))
         (child (cond
                 ((equal 1 (length entries)) (car-safe entries))
                 ;; I added org-brain-entry-name here
                 ((not entries) (error (concat (org-brain-entry-name entry) " has no children")))
                 (t (org-brain-choose-entry "Goto child: " entries nil t)))))
    (org-brain-goto child)))

(provide 'pen-org-brain)
