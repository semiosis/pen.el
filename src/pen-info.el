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

(provide 'pen-info)
