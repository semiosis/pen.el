(require 'info)
(require 'helm)
(require 'helm-info)

(defun Info-summary ()
  "Display a brief summary of all Info commands."
  (interactive)
  (tv (documentation 'Info-mode)))

;; Remember that H-w points to get-path

(define-key Info-mode-map (kbd "w") 'Info-copy-current-node-name)
;; (define-key Info-mode-map (kbd "w") 'get-path)

;; info-setup

(advice-add 'Info-select-node :around #'around-advice-buffer-erase-trailing-whitespace-advice)

;; combine multiple sources from helm-info
(defun ap/helm-info-emacs-elisp-cl ()
  "Helm for Emacs, Elisp, and CL-library info pages."
  (interactive)
  (helm :sources '(helm-source-info-emacs
                   helm-source-info-elisp
                   helm-source-info-cl)))

;; j:hc-highlight-tabs

(defun font-lock-set-keywords-from-defaults (&optional force)
  "This forces font-lock to work from the defaults."
  (interactive)
  (if force
      (setq font-lock-keywords (eval (car font-lock-defaults)))
    (font-lock-add-keywords nil info-highlights 'APPEND)))

;; (etv (pps font-lock-keywords))

(defsetface info-quoted-face
  '((t :foreground "#b7b777"
       :background "#302020" ;; "#303030"
       ;; :weight bold
       :underline nil))
  "Face for highlighting specific quoted text such as ‘M-x’"
  :group 'info)

(defsetface info-doublequoted-face
            '((t :foreground "#b777b7"
                 :background "#302020" ;; "#303030"
                 ;; :weight bold
                 :underline nil))
            "Face for highlighting specific quoted text such as “diary file”"
            :group 'info)

(defsetface info-key-face
            '((t :foreground "Dark Violet"
                 :background "#302020" ;; "#303030"
                 ;; :weight bold
                 :underline nil))
            "Face for highlighting key text such as ‘<DEL>’"
            :group 'info)

;; I want this to be subtle, or it's annoying
(defsetface info-number-face
            '((t ;; :foreground "#5faaff"
               :foreground "#a07070"
               ;; :background "#203050" ;; "#303030"
               :background nil ;; "#303030"
               ;; :weight bold
               :underline nil))
            "Face for highlighting key text such as ‘<DEL>’"
            :group 'info)

(defsetface info-allcaps-face
            '((t :foreground "#999999"
                 :background "#373737" ;; "#303030"
                 ;; :weight bold
                 :underline nil))
            "Face for highlighting key text such as ‘<DEL>’"
            :group 'info)

(defsetface info-function-face
            '((t :foreground "#999999"
                 :background unspecified ;; "#303030"
                 ;; :weight bold
                 :underline nil))
            "Face for highlighting key text such as ‘calc-grab-rectangle’"
            :group 'info)

;; I haven't yet worked out why these highlights don't work especially well
;; [[info:(elisp) Prefix Command Arguments]]
;; How do I make syntax highlights which ignore the initial bit
;; such as Function: ?
(defset info-highlights
        '((" Variable: [^ ]*" . 'font-lock-constant-face)
          (" Macro: [^ ]*" . 'font-lock-builtin-face)
          ;; ("\\(?: Function: \\)[^ ]*" . 'font-lock-warning-face)
          ;; ("^      *['(].*" . 'info-code-face)
          ;; ("^      *.*" . 'info-code-face)
          (" Function: [^ ]*" . 'font-lock-warning-face)
          ("^\\**" . 'info-menu-star)
          (" [0-9]+\\. " . 'info-bold)
          ;; [[info:(org-super-agenda) Usage]]
          ;; For example: *Note:*
          (" \\*[^* ]+\\* " . 'info-bold)
          ;; [[info:(org) Feedback]]
          ;; For example: M-x org-submit-bug-report <RET>
          (" M-x .*" . 'info-bullet-point)
          ;; [[info:(org) Feedback]]
          ;; For example: $ emacs -Q -l /path/to/minimal-org.el
          ("^ +\\$ .*" . 'info-bullet-point)
          ("^ +([^)]*)" . 'info-bullet-point)
          ;; For example: :after magit
          ;; [[info:(magithub) Installation]]
          ("^ +:.*" . 'info-bullet-point)
          ("^ +.*)$" . 'info-bullet-point)
          ("•" . 'info-menu-star)
          ;; ("‘[^’]*’" . 'font-lock-warning-face)
          ;; ("‘.*’" . 'font-lock-warning-face)
          ;; ("[^[:ascii:]]C-" . 'font-lock-warning-face)
          ;; ("C-" . 'font-lock-warning-face)
          ;; ("[^[:ascii:]].*[^[:ascii:]]" . 'font-lock-comment-face)
          ;; ‘diary-file’
          ("[\u2018][^\u2019]*[\u2019]" . 'info-quoted-face)
          ;; “diary file”
          ("[\u201C][^\u201D]*[\u201D]" . 'info-doublequoted-face)
          ;; ("[\u201C]\\\\([^\u201D]*\\\\)[\u201D]" . 'info-doublequoted-face)
          ("<[^ ]+>" . 'info-key-face)
          (" [A-Z] \\([A-Z_-]+[ .,;]\\)+" . 'info-allcaps-face)
          (" [A-Z][A-Z_-]+ " . 'info-allcaps-face)
          (" [a-z]+\\(-[a-z]+\\)+" . 'info-function-face)
          ;; Sadly, couldn't find an adequate pattern for numbers
          ;; [[info:elisp#Regexp Backslash][Emacs Info: elisp#Regexp Backslash]]
          (" [0-9][0-9.*-+/]*[ ,.]" . 'info-number-face)
          (" Command: [^ ]*" . 'font-lock-keyword-face)))

(defun set-info-highlights ()
  (setq font-lock-defaults '(info-highlights))
  (font-lock-set-keywords-from-defaults t)

  ;; Make this nil because I don't want case-insensitive font-lock.
  ;; I want to be able to highlight ALL_CAPS stuff
  (setq font-lock-keywords-case-fold-search nil)

  ;; j:font-lock-defaults
  ;; generates:
  ;; j:font-lock-keywords

  (ignore-errors
    (save-excursion
      (goto-char (point-min))
      (search-forward "=====")
      (beginning-of-line)
      (let ((m (point))
            (p (point-max)))
        (font-lock-fontify-region m p))))
  ;; (with-buffer-region-beg-end (font-lock-fontify-region beg end))
  ;; (font-lock-update)
  )

;; (add-hook 'org-brain-after-visualize-hook 'set-info-highlights)
;; (remove-hook 'org-brain-after-visualize-hook 'set-info-highlights)
(add-hook 'Info-selection-hook 'set-info-highlights)

(defsetface info-code-face
  '((t
     ;; :foreground "#d2268b"
     :foreground "#777777"
     ;; :background "#2e2e2e"
     ;; :weight bold
     ;; :underline t
     ))
  "Face for info code blocks."
  :group 'info)

(defsetface info-bullet-point
            '((t
               ;; :foreground "#d2268b"
               :foreground "#777777"
               ;; :background "#2e2e2e"
               ;; :weight bold
               ;; :underline t
               ))
            "Face for info code blocks."
            :group 'info)

(defsetface info-bold
            '((t
               ;; :foreground "#d2268b"
               :foreground "#cc9977"
               :background "#4e2e2e"
               ;; :weight bold
               ;; :underline t
               ))
            "Face for info code blocks."
            :group 'info)

(defsetface info-menu-star
            '((((class color)) :foreground "#222222")
              (t :underline t))
  "Face used to emphasize `*' in an Info menu.
The face is assigned to the third, sixth, and ninth `*' for easier
orientation.  See `Info-nth-menu-item'.")

(define-key Info-mode-map (kbd "w") 'Info-copy-current-node-name)
(define-key Info-mode-map (kbd "w") 'org-info-copy-link)
(define-key Info-mode-map (kbd "a") 'Info-search-next)
(define-key Info-mode-map (kbd "A") 'Info-search-prev)


(defun org-info-copy-link ()
  "Copy a link to an Info file and node."
  (interactive)
  (when (eq major-mode 'Info-mode)
    (let ((link (concat "info:"
			            (file-name-nondirectory Info-current-file)
			            "#" Info-current-node))
	      (desc (concat (file-name-nondirectory Info-current-file)
			            "#" Info-current-node)))
      ;; (org-link-store-props :type "info" :file Info-current-file
	  ;;   	    :node Info-current-node
	  ;;   	    :link link :description desc)
      (xc (format "[[%s][%s]]" link (concat "Emacs Info: " desc))))))

(defsetface info-goto-menu-item-face
  '((t :foreground "#dd4400"
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for info-goto-menu-item buttons.")

(defun info-goto-menu-item (button)
  "."
  (let ((refverse (button-get button 'title))
        (book (button-get button 'book))
        (chapter (button-get button 'chapter))
        (verses (button-get button 'verses))
        (modname (or (and (or (major-mode-p 'bible-mode)
                              (major-mode-p 'bible-search-mode))
                          (s-upcase (bible-shorten-module-name bible-mode-book-module)))

                     (if (>= (prefix-numeric-value current-prefix-arg) 4)
                         (fz-bible-version)
                       "ESV"))))

    (tpop-fit-vim-string (pen-snc (cmd "bible-tpop-lookup" "-c" "-m" modname
                                       (concat
                                        book " " chapter ":" verses))))

    ;; si buffer pas ouvert, ouvrir sinon mettre a jour
    (comment
     (if (window-live-p (get-buffer-window org-verse-buffer))
         (org-verse-sidebar-refresh refverse book chapter verses)
       (org-verse-toggle-sidebar)
       (org-verse-sidebar-refresh refverse book chapter verses)))))

(define-button-type 'info-goto-menu-item-button
  'action #'info-goto-menu-item
  'follow-link t
  'face 'info-goto-menu-item-face
  'help-echo "Click to go to the menu item."
  'help-args "test")

;; Fixed
(defun Info-menu (menu-item &optional fork)
  "Go to the node pointed to by the menu item named (or abbreviated) MENU-ITEM.
The menu item should one of those listed in the current node's menu.
Completion is allowed, and the default menu item is the one point is on.
If FORK is non-nil (interactively with a prefix arg), show the node in
a new Info buffer.  If FORK is a string, it is the name to use for the
new buffer."
  (interactive
   (let (;; If point is within a menu item, use that item as the default
         (default nil)
         (p (point))
         beg
         (case-fold-search t))
     (save-excursion
       (goto-char (point-min))
       (if (not (search-forward "\n* menu:" nil t))
           (user-error "No menu in this node"))
       (setq beg (point))
       (and (< (point) p)
            (save-excursion
              (goto-char p)
              (end-of-line)
              (if (re-search-backward (concat "\n\\* +\\("
                                              Info-menu-entry-name-re
                                              "\\):")
                                      beg t)
                  (setq default (match-string-no-properties 1))))))
     
     (setq default (or (sor default)
                       t))
     
     (let ((item nil))
       (while (null item)
         (setq item (let ((completion-ignore-case t)
                          (Info-complete-menu-buffer (current-buffer)))
                      ;; (tv (fz (Info-complete-menu-item "" nil t) nil nil (format-prompt "Menu item" default)))
                      ;; (tv (pps (Info-complete-menu-item "" nil t)))

                      ;; This is the same call
                      ;; (fz '("Basic Tutorial" "Arithmetic Tutorial" "Vector/Matrix Tutorial" "Types Tutorial" "Algebra Tutorial" "Programming Tutorial" "Answers to Exercises") nil nil "FZ Menu item: ")

                      ;; Figure out why this is not working properly:
                      ;; (fz (Info-complete-menu-item "" nil t) nil nil (format-prompt "FZ Menu item" default))

                      ;; (completing-read "Menu item" #'Info-complete-menu-item nil t nil nil nil nil)
                      ;; Ah, OK, so default needs to be set to 't or to the string of the first element
                      ;; (completing-read "Menu item" '("Basic Tutorial" "Arithmetic Tutorial" "Vector/Matrix Tutorial" "Types Tutorial" "Algebra Tutorial" "Programming Tutorial" "Answers to Exercises") nil t nil nil t nil)
                      ;; (completing-read "Menu item" #'Info-complete-menu-item nil t nil nil nil "")

                      ;; Info-complete-menu-item has nothing to do with the bug as it returns a well formed list with its first element as a nonempty string

                      (completing-read (format-prompt "Menu item" (if (eq t default)
                                                                      nil
                                                                    default))
                                       #'Info-complete-menu-item nil t nil nil
                                       ;; nil
                                       ;; t
                                       default
                                       ;; (if (test-n default)
                                       ;;     default
                                       ;;   nil)
                                       ))))
       (list item current-prefix-arg)))
   Info-mode)
  ;; there is a problem here in that if several menu items have the same
  ;; name you can only go to the node of the first with this command.
  (Info-goto-node (Info-extract-menu-item menu-item)
                  (and fork
                       (if (stringp fork) fork menu-item))))

(defun Info-search-prev ()
  "Search for prev regexp from a previous `Info-search' command."
  (interactive nil Info-mode)
  (let ((case-fold-search Info-search-case-fold))
    (if Info-search-history
        (Info-search (car Info-search-history) nil nil nil 'backward)
      (call-interactively 'Info-search))))

;; https://stackoverflow.com/q/13174659

(defun pen-list-info-topics ()
  (let* ((file-paths (reverse (f-files "/usr/local/share/info/" nil t)))
         (basename-mants (mapcar
                          (-compose
                           (lambda (s) (s-replace-regexp "\.info.*" "" s))
                           'f-basename)
                          file-paths))
         (annotated (-zip basename-mants file-paths)))
    (fz
     annotated
     nil nil "Info file: ")))

(defun pen-go-system-info-file ()
  (interactive)
  (let ((main-topic (pen-list-info-topics)))
    (if main-topic
        (info main-topic))))

(define-key Info-mode-map (kbd "M") 'pen-go-system-info-file)

(defun pen-Info-get-text-contents ()
  (interactive)
  (let* ((fp (concat Info-current-file ".info"))
         (fpgz (concat fp ".gz"))
         (contents (or (and (f-exists? fp)
                            (cat fp))
                       (and (f-exists? fpgz)
                            ;; (fz (snc (concat (cmd "cat" fpgz) " | " (cmd "gunzip" "-") " | sed '//,$d'")))
                            (snc (concat (cmd "cat" fpgz) " | " (cmd "gunzip" "-")))))))

    ;; Clean it up for searching
    (if contents
        ;; (setq contents (snc (tv (concat "tr '\\000' '@' | /bin/sed -e '/^@/d' -e '0,/" (char-to-string ?\^_) "/d' -e '/^File: /d' -e '/^Tag Table:/,$d' -e '/^" (char-to-string ?\^_) "/d' -e '/^\\s\\+(line.*)$/d' -e 's/\\s\\+(line.*)$//'")) contents))
        (setq contents (snc "emacs-clean-info-file" contents))
      ;; (setq contents (snc "tr '\\000' '@' | /bin/sed -e '/^@/d' -e '0,/" (char-to-string ?\^_) "/d' -e '/^File: /d' -e '/^Tag Table:/,$d' | tv" contents))
      ;; (setq contents (snc "tr '\\000' '@' | tv | /bin/sed -e '/^@/d'" contents))
      ;; (setq contents (snc "/bin/sed -e '/^@/d'" contents))
      ;; (setq contents (snc "tr '\\000' '@' | tv | /bin/sed -e '/^@/d'" contents))
      ;; (setq contents (snc "tr '\\000' '@' | /bin/sed -e '/^@/d' '0,/" (char-to-string ?\^_) "/d' -e '/^File: /d' -e '/^Tag Table:/,$d' | tv" contents))
      )

    (ifietv 
     contents)))

(defun pen-Info-fz-info-file ()
  (interactive)
  (let ((contents (pen-Info-get-text-contents)))
    (if (sor contents)
        (let ((res (fz contents nil nil "Info-search node contents: ")))
          (if res
              (progn
                (Info-top-node)
                (setq res (pen-unregexify res))
                (setq Info-search-history (cons res Info-search-history))
                (Info-search res))))
      (message "pen-Info-fz-info-file: Not inside info node"))))

(define-key Info-mode-map (kbd "/") 'pen-Info-fz-info-file)

;; TODO Make it so I can select some text and then press ekm:s and it will search for selected text

(defun Info-search (regexp &optional bound _noerror _count direction)
  "Search for REGEXP, starting from point, and select node it's found in.
If DIRECTION is `backward', search in the reverse direction."
  (interactive (list (read-string
                      (format-prompt
                       "Regexp search%s" (car Info-search-history)
                       (if case-fold-search "" " case-sensitively"))
                      nil 'Info-search-history))
               Info-mode)
  (when (equal regexp "")
    (setq regexp (car Info-search-history)))
  (when regexp
    (setq Info-search-case-fold case-fold-search)
    (let* ((backward (eq direction 'backward))
           (onode Info-current-node)
           (ofile Info-current-file)
           (opoint (point))
           (opoint-min (point-min))
           (opoint-max (point-max))
           (ostart (window-start))
           (osubfile Info-current-subfile)
           (found
            (save-excursion
              (save-restriction
                (widen)
                (Info--search-loop regexp bound backward)))))

      (unless (or (not isearch-mode) (not Info-isearch-search)
                  Info-isearch-initial-node
                  bound
                  (and found (> found opoint-min) (< found opoint-max)))
        (signal 'user-search-failed (list regexp "end of node")))

      ;; If no subfiles, give error now.
      (unless (or found Info-current-subfile)
        (if isearch-mode
            (signal 'user-search-failed (list regexp "end of manual"))
          (let ((search-spaces-regexp Info-search-whitespace-regexp))
            (unless (if backward
                        (re-search-backward regexp nil t)
                      (re-search-forward regexp nil t))
              (signal 'user-search-failed (list regexp))))))

      (if (and (or bound (not Info-current-subfile)) (not found))
          (signal 'user-search-failed (list regexp)))

      (unless (or found bound)
        (unwind-protect
            ;; Try other subfiles.
            (let ((list ()))
              (with-current-buffer (marker-buffer Info-tag-table-marker)
                (goto-char (point-min))
                (search-forward "\n\^_\nIndirect:")
                (save-restriction
                  (narrow-to-region (point)
                                    (progn (search-forward "\n\^_")
                                           (1- (point))))
                  (goto-char (point-min))
                  ;; Find the subfile we just searched.
                  (search-forward (concat "\n" osubfile ": "))
                  ;; Skip that one.
                  (forward-line (if backward 0 1))
                  (if backward (forward-char -1))
                  ;; Make a list of all following subfiles.
                  ;; Each elt has the form (VIRT-POSITION . SUBFILENAME).
                  (while (not (if backward (bobp) (eobp)))
                    (if backward
                        (re-search-backward "\\(^.*\\): [0-9]+$")
                      (re-search-forward "\\(^.*\\): [0-9]+$"))
                    (goto-char (+ (match-end 1) 2))
                    (push (cons (read (current-buffer))
                                (match-string-no-properties 1))
                          list)
                    (goto-char (if backward
                                   (1- (match-beginning 0))
                                 (1+ (match-end 0)))))
                  ;; Put in forward order
                  (setq list (nreverse list))))
              (while list
                (message "Searching subfile %s..." (cdr (car list)))
                (Info-read-subfile (car (car list)))
                (when backward (goto-char (point-max)))
                (setq list (cdr list))
                (setq found (Info--search-loop regexp nil backward))
                (if found
                    (setq list nil)))
              (if found
                  (message "")
                (signal 'user-search-failed
                        `(,regexp ,@(if isearch-mode '("end of manual"))))))
          (if (not found)
              (progn (Info-read-subfile osubfile)
                     (goto-char opoint)
                     (Info-select-node)
                     (set-window-start (selected-window) ostart)))))

      (if (and (string= osubfile Info-current-subfile)
               (> found opoint-min)
               (< found opoint-max))
          ;; Search landed in the same node
          (goto-char found)
        (deactivate-mark)
        (widen)
        (goto-char found)
        (save-match-data (Info-select-node)))

      ;; Use string-equal, not equal, to ignore text props.
      (or (and (string-equal onode Info-current-node)
               (equal ofile Info-current-file))
          (and isearch-mode isearch-wrapped
               (eq opoint (if isearch-forward opoint-min opoint-max)))
          (setq Info-history (cons (list ofile onode opoint)
                                   Info-history))))))

(provide 'pen-info)
