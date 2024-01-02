(require 'wordnut)
(require 'org)
(require 'org-macs)
(require 'org-goto)
(require 'org-table)
(require 'evil-org)
(load-library "find-lisp")
;; https://writequit.org/articles/emacs-org-mode-generate-ids.html#automating-id-creation
(require 'org-id)
(require 'org-clock)
(advice-add 'org-clocking-p :around #'ignore-errors-around-advice)
(require 'org-habit)
(require 'org-translate)
(require 'org-link-minor-mode)
(require 'org-parser)
(require 'org-sql)
(require 'org-ql)
;; There appears to be an issue with helm-org-ql currently
;; TODO Fix it
;; (require 'helm-org-ql)

(define-key org-link-minor-mode-map (kbd "C-c C-o") 'org-open-at-point)

;; https://github.com/suvayu/.emacs.d/blob/master/lisp/nifty.el
;; recursively find .org files in provided directory
;; modified from an Emacs Lisp Intro example
(defun sa-find-org-file-recursively (&optional directory filext)
  "Return .org and .org_archive files recursively from DIRECTORY.
If FILEXT is provided, return files with extension FILEXT instead."
  (interactive "DDirectory: ")
  (let* (org-file-list
	     (case-fold-search t)	      ; filesystems are case sensitive
	     (file-name-regex "^[^.#].*") ; exclude dot, autosave, and backup files
	     (filext (or filext "org$\\\|org_archive"))
	     (fileregex (format "%s\\.\\(%s$\\)" file-name-regex filext))
	     (cur-dir-list (directory-files directory t file-name-regex)))
    ;; loop over directory listing
    (dolist (file-or-dir cur-dir-list org-file-list) ; returns org-file-list
      (cond
       ((file-regular-p file-or-dir)         ; regular files
	    (if (string-match fileregex file-or-dir) ; org files
	        (add-to-list 'org-file-list file-or-dir)))
       ((file-directory-p file-or-dir)
	    (dolist (org-file (sa-find-org-file-recursively file-or-dir filext)
			              org-file-list) ; add files found to result
	      (add-to-list 'org-file-list org-file)))))))

;; nadvice - proc is the original function, passed in. do not modify
;; nadvice - proc is the original function, passed in. do not modify
(defun org-open-at-point-around-advice (proc &rest args)
  (try
   (let ((res (apply proc args)))
     res)
   (let ((url (sor (sh/xurls (current-line-string)))))
     (if url
         (cond
          ((string-match-p "^file://" url) (find-file (pen-cl-sn "sed 's=^file://=='" :stdin url :chomp t)))
          (t (eww url)))))
   (error "Nothing found here")))
(advice-add 'org-open-at-point :around #'org-open-at-point-around-advice)
(advice-remove 'org-open-at-point #'org-open-at-point-around-advice)

;; Disable indentation
(setq org-adapt-indentation nil)

(setq org-blank-before-new-entry '((heading . t) (plain-list-item . t)))
(setq org-todo-keywords
      '((sequence "TODO" "|" "DONE" "DISCARD" "FAILED")))

(defvar docsdir (f-join penconfdir "documents"))
(if (not (f-directory-p docsdir))
    (f-mkdir docsdir))

(defvar agendadir (f-join penconfdir "documents/agenda"))
(if (not (f-directory-p agendadir))
    (f-mkdir agendadir))

(defun org-agenda-refresh ()
  (interactive)
  (setq org-agenda-files
        (append
         ;; (find-lisp-find-files agendadir "\.org$")
         (sa-find-org-file-recursively agendadir "org")
         ;; (sa-find-org-file-recursively some-other-dir "org")
         ))
  (ignore-errors (org-agenda-redo)))

(org-agenda-refresh)

(add-hook 'org-mode-hook (λ () (modify-syntax-entry (string-to-char "\u25bc") "w"))) ; Down arrow for collapsed drawer.

; Speed up org-mode
; Reduce the number of Org agenda files to avoid slowdowns due to hard drive accesses.
; Reduce the number of ‘DONE’ and archived headlines so agenda operations that skip over these can finish faster.
; Do not dim blocked tasks:
(setq org-agenda-dim-blocked-tasks nil)
; Stop preparing agenda buffers on startup:
(setq org-agenda-inhibit-startup nil)
; Disable tag inheritance for agendas:
(setq org-agenda-use-tag-inheritance nil)

(setq org-cycle-separator-lines 0)

(setq org-link-file-path-type 'absolute)
(setq org-startup-indented t)
(setq org-hide-leading-stars t)         ; This uses the face 'org-hide' behind the scenes. Therefore, it wont hide in vt100
(setq org-odd-level-only nil)
(setq org-insert-heading-respect-content nil)
(setq org-M-RET-may-split-line '((item) (default . t)))
(setq org-special-ctrl-a/e t)
(setq org-return-follows-link nil)

(setq org-use-speed-commands t)
(setq org-speed-commands-user
      '(("x" . org-cut-subtree)
        ("n" . (org-speed-move-safe 'org-next-visible-heading))
        ("p" . (org-speed-move-safe 'org-previous-visible-heading))
        ("j" . (org-speed-move-safe 'org-forward-heading-same-level))
        ("k" . (org-speed-move-safe 'org-backward-heading-same-level))
        ;; ("g"             . org-goto)
        ("g" . counsel-outline)
        ("o" . counsel-outline)
        ;; ("G" . (org-refile t))
        ))

(setq org-startup-align-all-tables nil)
(setq org-log-into-drawer nil)
(setq org-tags-column 1)
(setq org-ellipsis " \u25bc" )
;; (setq org-speed-commands-user nil)
(setq org-blank-before-new-entry '((heading . nil) (plain-list-item . nil)))
(setq org-completion-use-ido t)
(setq org-indent-mode -1)               ; it's ugly with indent-mode disabled. But adding extra stars in vt100 is unacceptable
(setq org-startup-indented nil) ;; this prevents spacemacs from turning on indent mode automatically
;; (setq org-indent-mode t) ;; this looks nice but is annoying in vt100 ;; this added extra stars to the start
;; and needs an annoying redraw
(setq org-startup-truncated nil)
;; (setq org-startup-truncated t) ;; I think pen-i want this ; this isn't truncating long lines so disable it
(setq auto-fill-mode -1)
;; (setq-default fill-column 99999)
;; (setq fill-column 99999)
(global-auto-revert-mode t)
(prefer-coding-system 'utf-8)
;(cua-mode t) ;; keep the cut and paste shortcut keys people are used to.
(cua-mode nil) ;; keep the cut and paste shortcut keys people are used to.
(setq cua-auto-tabify-rectangles nil) ;; Don't tabify after rectangle commands
(transient-mark-mode nil)               ;; No region when it is not highlighted
(setq cua-keep-region-after-copy t)

;; python
(setq-default indent-tabs-mode nil)    ; use only spaces and no tabs
(setq default-tab-width 4)

;; pen-i like pageup page down for buffer changes.
(global-set-key [(control next)] 'next-buffer)
(global-set-key [(control prior)] 'previous-buffer)

;; Add copy a whole line to clipboard to Emacs, bound to meta-c.
(defun quick-copy-line ()
  "Copy the whole line that point is on and move to the beginning of the next line.
    Consecutive calls to this command append each line to the
    kill-ring."
  (interactive)
  (let ((beg (line-beginning-position 1))
        (end (line-beginning-position 2)))
    (if (eq last-command 'quick-copy-line)
        (kill-append (buffer-substring beg end) (< end beg))
      (kill-new (buffer-substring beg end))))
  (beginning-of-line 2)
  (message "Line appended to kill-ring."))

;; Add inserting current date time.
(defun pen-insert-date (prefix)
    "Insert the current date. With prefix-argument, use ISO format. With
   two prefix arguments, write out the day and month name."
    (interactive "P")
    (let ((format (cond
                   ((not prefix) "%Y-%m-%d %H:%M")
                   ((equal prefix '(4)) "%Y-%m-%d")
                   ((equal prefix '(16)) "%A, %d. %B %Y")))
          )
      (insert (format-time-string format))))

(defun output-up-heading-top (arg)
  "Goes to the top-level heading"
  (interactive "p")
  ;; (kbd "M-1 0 0 M-a")
  (dotimes (interactive 100)
    (outline-up-heading arg)))

(advice-add 'output-up-heading-top :around #'ignore-errors-around-advice)

                                        ; HIGHLIGHT LATEX TEXT IN ORG MODE
(setq org-highlight-latex-and-related '(latex))

(use-package org-table
  :defer t
  :config
  (progn

    (defun org-table-mark-field ()
      "Mark the current table field."
      (interactive)
      ;; Do not try to jump to the beginning of field if the point is already there
      (when (not (looking-back "|[[:blank:]]?"))
        (org-table-beginning-of-field 1))
      (set-mark-command nil)
      (org-table-end-of-field 1))

    (defhydra hydra-org-table-mark-field
      (:body-pre (org-table-mark-field)
                 :color red
                 :hint nil)
      "
  ^^      _k_     ^^
 _h_  selection  _l_
  ^^      _j_     ^^
"
      ("x" exchange-point-and-mark "exchange point/mark")
      ("l" (λ (arg)
             (interactive "p")
             (when (eq 1 arg)
               (setq arg 2))
             (org-table-end-of-field arg)))
      ("h" (λ (arg)
             (interactive "p")
             (when (eq 1 arg)
               (setq arg 2))
             (org-table-beginning-of-field arg)))
      ("j" next-line)
      ("k" previous-line)
      ("q" nil "cancel" :color blue))

    (bind-keys
     :map org-mode-map
     :filter (org-at-table-p)
     ("M-r" . hydra-org-table-mark-field/body))))

(defadvice org-end-of-line (around pen-org-eol-around activate)
  (interactive)

  (let ((visual-line-mode -1))
    (if (interactive-p)
	(call-interactively (ad-get-orig-definition 'org-end-of-line))
      ad-do-it)))

(setq org-yank-folded-subtrees nil)
(setq org-yank-adjusted-subtrees t)

(define-key org-mode-map (kbd "M-J") 'evil-join)

(when (executable-find "iceweasel") (add-to-list 'org-file-apps '("\\.x?html\\'" . "iceweasel %s")))
(remove-from-list 'org-file-apps '("\\.pdf\\'" . default))

(defadvice org-babel-do-load-languages (around org-babel-do-load-languages-around activate)
  (setq org-babel-load-languages (delq (assoc 'sh org-babel-load-languages) org-babel-load-languages))
  ad-do-it)

;; prevent org mode from automatically executing babel blocks. hopefully this also prevents blocks from being executed when clicking on the block
(setq org-export-babel-evaluate nil)

;; This is important to let org-mode highlight code blocks
(setq org-src-fontify-natively t)

;; This is for the "j" menu
(defconst org-goto-help
  "Browse buffer copy, to find location or copy text.%s
Start typing to search.
\[C-m]           jump to location
\[C-g]           quit and return to previous location
\[PgUp]/[PgDown] up and down page
\[Up]/[Down]     next/prev headline
\[C-i]           cycle visibility
\[/]             org-occur")

(defun pen-org-publish-current-file ()
  (interactive)

  (pen-ns "Don't forget to add these under the headings: :PROPERTIES: \n :CUSTOM_ID: pen-headline-2 \n :END:")
  ;; (xc ":PROPERTIES: \n :CUSTOM_ID: pen-headline-2 \n :END:")

  ;; :PROPERTIES:
  ;; :CUSTOM_ID: server-config-yaml
  ;; :END:

  ;; Dont use this. I need to set up projects for this
  ;; (org-publish-current-file)

  (let ((htmlfn
         (replace-regexp-in-string "\\(.*\\)\\.org$" "\\1.html" (buffer-file-name))))

    (call-interactively #'org-html-export-as-html)

    ;; Need a shell script to touch a new file, including making the directories with mkdir -p
    ;; (replace-regexp-in-string "\\(.*\\)\\.org$" "\\1.html" (buffer-file-name))
    (set-visited-file-name htmlfn)
    ;; (save-current-buffer)
    (save-buffer)
    (kill-current-buffer)

    (pen-bl ff-view htmlfn)
    (delete-window))
  ;; Open chrome to this html file
  )

;; This fixes a compatibility with older org
;; Could not run org-edit-special without this
(defun org-get-indentation (&optional line)
  "Get the indentation of the current line, interpreting tabs.
When LINE is given, assume it represents a line and compute its indentation."
  (if line
      (when (string-match "^ *" (org-remove-tabs line))
	(match-end 0))
    (save-excursion
      (beginning-of-line 1)
      (skip-chars-forward " \t")
      (current-column))))

;; This works! The function moved to org-compat
(advice-add 'org-goto--set-map :after '(lambda (&rest args) (define-key org-goto-map (kbd "<next>") nil)))

(defun org-mode-hook-after ()
  (interactive)
  (if (s-match "/glossary\.org$" (get-path))
      (org-global-cycle 1))
  ;; This broke lsp company completion
  ;; (add-to-list 'company-backends 'company-ispell)
  )

;; (remove-from-list 'company-backends 'company-ispell)

(add-hook 'org-mode-hook 'org-mode-hook-after t)
(add-hook 'org-mode-hook #'company-mode)

(nconc org-modules
       '(
         org-capture
         org-habit
         org-id
         org-protocol
         org-brain
         ))

;; This should not care about ellipsis and go to the end anyway
(defun pen-org-end-of-line (&optional n)
  "If this is a headline, and `org-special-ctrl-a/e' is not nil or
symbol `reversed', ignore tags on the first attempt, and only
move to after the tags when the cursor is already beyond the end
of the headline.

If `org-special-ctrl-a/e' is symbol `reversed' then ignore tags
on the second attempt.

With argument N not nil or 1, move forward N - 1 lines first."
  (interactive "^p")
  (let ((origin (point))
        (special (pcase org-special-ctrl-a/e
                   (`(,_ . ,C-e) C-e) (_ org-special-ctrl-a/e)))
        deactivate-mark)
    ;; First move to a visible line.
    (if (bound-and-true-p visual-line-mode)
        (beginning-of-visual-line n)
      (move-beginning-of-line n))
    (cond
     ;; At a headline, with tags.
     ((and special
           (save-excursion
             (beginning-of-line)
             (let ((case-fold-search nil))
               (looking-at org-complex-heading-regexp)))
           (match-end 5))
      (let ((tags (save-excursion
                    (goto-char (match-beginning 5))
                    (skip-chars-backward " \t")
                    (point))))
        (cond ((eq special 'reversed)
               (if (and (= origin (line-end-position))
                        (eq this-command last-command))
                   (goto-char tags)
                 (end-of-line)))
              (t
               (if (or (< origin tags) (= origin (line-end-position)))
                   (goto-char tags)
                 (end-of-line))))))
     (t (end-of-line)))))

(defun tvipe-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (pen-sps (concat "vs " (pen-q newfile)))))
(defalias 'tvipe-org-table-export-tsv 'tvipe-org-table-export)

(defun etv-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (esph (pen-lm (pen-term-nsfa (concat "vs " (pen-q newfile)))))))
(defalias 'etv-org-table-export-tsv 'etv-org-table-export)

(defun fpvd-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (pen-sps (concat "fpvd " (pen-q newfile)))))

(advice-add 'kill-buffer :around #'advise-to-yes)
;; (advice-add 'fpvd-org-table-export :around #'advise-to-yes)

(defun efpvd-org-table-export ()
  (interactive)
  (let ((newfile (org-babel-temp-file "org-table" ".tsv")))
    (org-table-export newfile "orgtbl-to-tsv")
    (esph (pen-lm (pen-term-nsfa (concat "fpvd " (pen-q newfile)))))))

(defun org-copy-src-block ()
  (interactive)
  (shut-up (xc (org-get-src-block-here))))

(defun org-get-src-block-here ()
  (interactive)
  (org-edit-src-code)
  (mark-whole-buffer)
  (let ((contents (chomp (pen-selected-text))))
    ;; (easy-kill 1)
    (org-edit-src-abort)
    contents))

(defun org-copy-thing-here ()
  (interactive)
  (if (or (org-in-src-block-p)
          (org-in-block-p '("src" "example" "verbatim" "clocktable" "example")))
      (org-copy-src-block)
    (self-insert-command 1)))

(pen-alist-setcdr 'org-link-frame-setup 'file 'find-file)

(defun pen-org-list-top-level-headings ()
  (ignore-errors (mapcar 'str (mapcar 'car (org-imenu-get-tree)))))

(defun pen-org-select-heading (name)
  (interactive (list (fz (pen-org-list-top-level-headings))))
  (let* ((λ (-filter (λ (e) (string-equal name (car e))) (org-imenu-get-tree)))
         (sel (if (> 0 (length l))
                  ;; I need an fz that lets me pick by a different thing
                  ;; (fz l)
                  (car l)
                (car l))))
    (setq sel (car sel))
    (if (sor sel)
        (goto-char (get-text-property 0 'org-imenu-marker sel)))))

(advice-remove 'org-clock-kill-emacs-query #'ignore-errors-around-advice)

;; This broke org. Why did I have it here? Did I make changes?
;; It was badly formatted when I copied it too.
;; I added eww-cached
(defun org-activate-links--text-properties (limit)
  "Add link properties to links.
This includes angle, plain, and bracket links."
  (catch :exit
    (while (re-search-forward org-link-any-re limit t)
      (let* ((start (match-beginning 0))
             (end (match-end 0))
             (visible-start (or (match-beginning 3) (match-beginning 2)))
             (visible-end (or (match-end 3) (match-end 2)))
             (style (cond ((eq ?< (char-after start)) 'angle)
                          ((eq ?\[ (char-after (1+ start))) 'bracket)
                          (t 'plain))))
        (when (and (memq style org-highlight-links)
                   ;; Do not span over paragraph boundaries.
                   (not (string-match-p org-element-paragraph-separate
                                        (match-string 0)))
                   ;; Do not confuse plain links with tags.
                   (not (and (eq style 'plain)
                             (let ((face (get-text-property
                                          (max (1- start) (point-min)) 'face)))
                               (if (consp face) (memq 'org-tag face)
                                 (eq 'org-tag face))))))
          (let* ((link-object (save-excursion
                                (goto-char start)
                                (save-match-data (org-element-link-parser))))
                 (link (org-element-property :raw-link link-object))
                 (type (org-element-property :type link-object))
                 (path (org-element-property :path link-object))
                 (face-property (pcase (org-link-get-parameter type :face)
                                  ((and (pred functionp) face) (funcall face path))
                                  ((and (pred facep) face) face)
                                  ((and (pred consp) face) face) ;anonymous
                                  ;; (_ 'org-link)
                                  (_
                                   (if (lg-url-cache-exists link)
                                       'eww-cached
                                     'org-link))))
                 (properties            ;for link's visible part
                  (list 'mouse-face (or (org-link-get-parameter type :mouse-face)
                                        'highlight)
                        'keymap (or (org-link-get-parameter type :keymap)
                                    org-mouse-map)
                        'help-echo (pcase (org-link-get-parameter type :help-echo)
                                     ((and (pred stringp) echo) echo)
                                     ((and (pred functionp) echo) echo)
                                     (_ (concat "LINK: " link)))
                        'htmlize-link (pcase (org-link-get-parameter type
                                                                     :htmlize-link)
                                        ((and (pred functionp) f) (funcall f))
                                        (_ `(:uri ,link)))
                        'font-lock-multiline t)))
            (org-remove-flyspell-overlays-in start end)
            (org-rear-nonsticky-at end)
            (if (not (eq 'bracket style))
                (progn
                  (add-face-text-property start end face-property)
                  (add-text-properties start end properties))
              ;; Initialize folding when used outside org-mode.
              (unless (or (derived-mode-p 'org-mode)
                          (and (org-fold-folding-spec-p 'org-link-description)
                               (org-fold-folding-spec-p 'org-link)))
                (org-fold-initialize (or (and (stringp org-ellipsis) (not (equal "" org-ellipsis)) org-ellipsis)
                                         "...")))
              ;; Handle invisible parts in bracket links.
              (let ((spec (or (org-link-get-parameter type :display)
                              'org-link)))
                (unless (org-fold-folding-spec-p spec)
                  (org-fold-add-folding-spec spec
                                             (cdr org-link--link-folding-spec)
                                             nil
                                             'append)
                  (org-fold-core-set-folding-spec-property spec :visible t))
                (org-fold-region start end nil 'org-link)
                (org-fold-region start end nil 'org-link-description)
                ;; We are folding the whole emphasized text with SPEC
                ;; first.  It makes everything invisible (or whatever
                ;; the user wants).
                (org-fold-region start end t spec)
                ;; The visible part of the text is folded using
                ;; 'org-link-description, which is forcing this part of
                ;; the text to be visible.
                (org-fold-region visible-start visible-end t 'org-link-description)
                (add-text-properties start end properties)
                (add-face-text-property start end face-property)
                (org-rear-nonsticky-at visible-start)
                (org-rear-nonsticky-at visible-end)))
            (let ((f (org-link-get-parameter type :activate-func)))
              (when (functionp f)
                (funcall f start end path (eq style 'bracket))))
            (throw :exit t)))))         ;signal success
    nil))


(define-key org-agenda-mode-map (kbd "r") 'org-agenda-refresh)
(define-key org-mode-map (kbd "M-{") nil) ; remove old binding
(define-key org-mode-map (kbd "M-p") 'org-backward-element)
(define-key org-mode-map (kbd "M-}") nil) ; remove old binding
(define-key org-mode-map (kbd "M-n") 'org-forward-element)
(define-key org-mode-map (kbd "M-q M-n") #'org-insert-heading-after-current)
(define-key org-mode-map (kbd "M-q M-o") #'org-insert-heading-after-current)
(define-key org-mode-map (kbd "C-M-a") #'output-up-heading-top)
(define-key org-mode-map (kbd "M-a") #'outline-up-heading)
(define-key org-mode-map (kbd "M-p") #'org-backward-heading-same-level)
(define-key org-mode-map (kbd "M-n") #'org-forward-heading-same-level)
(define-key org-mode-map (kbd "M-e") #'org-next-visible-heading)
(define-key org-mode-map (kbd "M-E") #'org-previous-visible-heading)
(define-key org-mode-map (kbd "M-9") 'handle-docs)
(define-key org-mode-map (kbd "M-8") nil)
(define-key org-mode-map (kbd "C-c M-p") #'pen-org-publish-current-file)
(define-key org-mode-map "\C-e" 'pen-org-end-of-line)
(define-key org-mode-map (kbd "M-P") 'handle-preverr)
(define-key org-mode-map (kbd "M-N") 'handle-nexterr)
(define-key org-mode-map (kbd "M-l M-j M-w") 'handle-spellcorrect)
(define-key org-mode-map (kbd "M-RET") 'org-meta-return)
(define-key org-mode-map (kbd "M-c") 'org-copy-thing-here)
(define-key org-mode-map (kbd "M-c") 'nil)
(define-key org-mode-map (kbd "M-*") 'pen-evil-star-maybe)

(require 'poly-org)
(remove-from-list 'auto-mode-alist '("\\.org\\'" . poly-org-mode))

;; This makes the org-man message go away
(advice-add 'org-link-minor-mode :around #'shut-up-around-advice)


;; nadvice - proc is the original function, passed in. do not modify
(defun org-agenda-around-advice (proc &rest args)
  (org-agenda-refresh)
  (let ((res (apply proc args)))
    res))
(advice-add 'org-agenda :around #'org-agenda-around-advice)
;; (advice-remove 'org-agenda #'org-agenda-around-advice)

;; org-todo
;; org-auto-repeat-maybe
(defun org-entry-put (pom property value)
  "Set PROPERTY to VALUE for entry at point-or-marker POM.

If the value is nil, it is converted to the empty string.  If it
is not a string, an error is raised.  Also raise an error on
invalid property names.

PROPERTY can be any regular property (see
d`org-special-properties').  It can also be \"TODO\",
\"PRIORITY\", \"SCHEDULED\" and \"DEADLINE\".

For the last two properties, VALUE may have any of the special
values \"earlier\" and \"later\".  The function then increases or
decreases scheduled or deadline date by one day."
  (cond ((null value) (setq value ""))
        ((not (stringp value)) (error "Properties values should be strings"))
        ((not (org--valid-property-p property))
         (user-error "Invalid property name: \"%s\"" property)))
  (org-no-read-only
   (org-with-point-at pom
     (if (or (not (featurep 'org-inlinetask)) (org-inlinetask-in-task-p))
         (org-back-to-heading-or-point-min t)
       (org-with-limited-levels (org-back-to-heading-or-point-min t)))
     (let ((beg (point)))
       (cond
        ((equal property "TODO")
         (cond ((not (org-string-nw-p value)) (setq value 'none))
               ((not (member value org-todo-keywords-1))
                (user-error "\"%s\" is not a valid TODO state" value)))
         (org-todo value)
         (org-align-tags))
        ((equal property "PRIORITY")
         (org-priority (if (org-string-nw-p value) (string-to-char value) ?\s))
         (org-align-tags))
        ((equal property "SCHEDULED")
         (forward-line)
         (if (and (looking-at-p org-planning-line-re)
                  (re-search-forward
                   org-scheduled-time-regexp (line-end-position) t))
             (cond ((string= value "earlier") (org-timestamp-change -1 'day))
                   ((string= value "later") (org-timestamp-change 1 'day))
                   ((string= value "") (org-schedule '(4)))
                   (t (org-schedule nil value)))
           (if (member value '("earlier" "later" ""))
               (call-interactively #'org-schedule)
             (org-schedule nil value))))
        ((equal property "DEADLINE")
         (forward-line)
         (if (and (looking-at-p org-planning-line-re)
                  (re-search-forward
                   org-deadline-time-regexp (line-end-position) t))
             (cond ((string= value "earlier") (org-timestamp-change -1 'day))
                   ((string= value "later") (org-timestamp-change 1 'day))
                   ((string= value "") (org-deadline '(4)))
                   (t (org-deadline nil value)))
           (if (member value '("earlier" "later" ""))
               (call-interactively #'org-deadline)
             (org-deadline nil value))))
        ((member property org-special-properties)
         (error "The %s property cannot be set with `org-entry-put'" property))
        (t
         (org-fold-core-ignore-modifications
           (let* ((range (org-get-property-block beg 'force))
                  (end (cdr range))
                  (case-fold-search t))
             (goto-char (car range))
             (if (re-search-forward (org-re-property property nil t) end t)
                 (progn
                   ;; I fixed a bug here.
                   ;; The match was changing, and the match-beginnging
                   ;; and match-end were no longer correct.
                   ;; But placing the let here seems to have  fixed it.
                   (let ((b (match-beginning 0))
                         (e (match-end 0)))
                     (delete-region b e)
                     (goto-char b)))
               (goto-char end)
               (insert-and-inherit "\n")
               (backward-char))
             (insert-and-inherit ":" property ":")
             (when value (insert-and-inherit " " value))
             (org-indent-line))))))
     (run-hook-with-args 'org-property-changed-functions property value))))

(defun sort-string-lessp (i j)
  "[internal] String comparator."
  (cond
   ((string= i j) 0)
   ((string< i j) -1)
   (t 1)))

(defun pen-org-add-tag ()
  (interactive)
  (let* ((tags (mapcar
                (lambda (s) (s-replace "_" " " s))
                (mapcar 'str (org-get-tags))))
         (all_agenda_tags (mapcar
                           (lambda (s) (s-replace "_" " " s))
                           (org-agenda-list-tags)))
         (sel (fz all_agenda_tags nil nil "Add tag:"))
         ;; (e (etv sel))
         (tags (-uniq (-sort 'sort-string-lessp (append tags (list sel))))))
    (if (sor sel)
        (org-set-tags
         (mapcar
          (lambda (s) (s-replace " " "_" s))
          tags)))))

;; Remember these
(setq org-speed-commands
      '(("Outline Navigation")
        ("n" org-speed-move-safe 'org-next-visible-heading)
        ("p" org-speed-move-safe 'org-previous-visible-heading)
        ("f" org-speed-move-safe 'org-forward-heading-same-level)
        ("b" org-speed-move-safe 'org-backward-heading-same-level)
        ("F" . org-next-block)
        ("B" . org-previous-block)
        ("u" org-speed-move-safe 'outline-up-heading)
        ("j" . org-goto)
        ("g" org-refile
         '(4))
        ("Outline Visibility")
        ("c" . org-cycle)
        ("C" . org-shifttab)
        (" " . org-display-outline-path)
        ("s" . org-toggle-narrow-to-subtree)
        ("k" . org-cut-subtree)
        ("=" . org-columns)
        ("Outline Structure Editing")
        ("U" . org-metaup)
        ("D" . org-metadown)
        ("r" . org-metaright)
        ("l" . org-metaleft)
        ("R" . org-shiftmetaright)
        ("L" . org-shiftmetaleft)
        ("i" progn
         (forward-char 1)
         (call-interactively 'org-insert-heading-respect-content))
        ("^" . org-sort)
        ("w" . org-refile)
        ("a" . org-archive-subtree-default-with-confirmation)
        ("@" . org-mark-subtree)
        ("#" . org-toggle-comment)
        ("Clock Commands")
        ("I" . org-clock-in)
        ("O" . org-clock-out)
        ("Meta Data Editing")
        ("t" . org-todo)
        ("," org-priority)
        ("0" org-priority 32)
        ("1" org-priority 65)
        ("2" org-priority 66)
        ("3" org-priority 67)
        (":" . org-set-tags-command)
        ("T" . pen-org-add-tag)
        ("e" . org-set-effort)
        ("E" . org-inc-effort)
        ("W" lambda
         (m)
         (interactive "sMinutes before warning: ")
         (org-entry-put
          (point)
          "APPT_WARNTIME" m))
        ("Agenda Views etc")
        ("v" . org-agenda)
        ("/" . org-sparse-tree)
        ("Misc")
        ("o" . org-open-at-point)
        ("?" . org-speed-command-help)
        ("<" org-agenda-set-restriction-lock 'subtree)
        (">" org-agenda-remove-restriction-lock)))

(defun org-toggle-link-display ()
  "Toggle the literal or descriptive display of links."
  (interactive)
  (if org-descriptive-links
      (progn (org-remove-from-invisibility-spec '(org-link))
         (org-restart-font-lock)
         (setq org-descriptive-links nil))
    (progn (add-to-invisibility-spec '(org-link))
       (org-restart-font-lock)
       (setq org-descriptive-links t))))

(define-key org-mode-map (kbd "C-c l") 'org-toggle-link-display)

(defun org-get-link ()
  (interactive)
  (shut-up (call-interactively 'org-store-link))
  (with-temp-buffer
    (call-interactively 'org-insert-last-stored-link)
    (buffer-string)))

(defun org-copy-link ()
  (interactive)
  (xc (org-get-link)))

(define-key pen-map (kbd "C-c L") 'org-copy-link)

(require 'org-ref)
(require 'org-ref-prettify)

(provide 'pen-org)
