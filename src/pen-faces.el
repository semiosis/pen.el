(require 'spacemacs-dark-theme)
(load-theme 'spacemacs-dark t)

(defface org-bold
  '((t :foreground "#d2268b"
       :background "#2e2e2e"
       :weight bold
       :underline t))
  "Face for org-mode bold."
  :group 'org-faces)

(defface org-italic
  '((t :foreground "#8bd226"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline t))
  "Face for org-mode italic."
  :group 'org-faces)

(defface org-underline
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline t))
  "Face for org-mode underline."
  :group 'org-faces)

(defsetface org-strikethrough
  '((t :foreground "#660000"
       :weight normal
       :strike-through t))
  "Face for org-mode strikethrough.")

(setq org-emphasis-alist
  '(("*" ;; (bold :foreground "Orange" )
     org-bold)
    ("/" ;; italic
     org-italic)
    ("_" ;; underline
     org-underline
     )
    ("=" ;; (:background "maroon" :foreground "white")
     org-verbatim verbatim)
    ("$HOME" ;; (:background "deep sky blue" :foreground "MidnightBlue")
     org-code verbatim)
    ;; ("+" (:strike-through t))
    ("+" org-strikethrough)))

(set-face-foreground 'org-verbatim "#f07000")
;; (set-face-foreground 'org-code "#f070f0")
(set-face-foreground 'org-code "#c0c0c0")

(defun pen-list-faces (&optional regexp)
  "List all faces, using the same sample text in each.
The sample text is a string that comes from the variable
`list-faces-sample-text'.

If REGEXP is non-nil, list only those faces with names matching
this regular expression.  When called interactively with a prefix
argument, prompt for a regular expression using `read-regexp'."
  (interactive (list (and current-prefix-arg
                          (read-regexp "List faces matching regexp"))))
  (let ((all-faces (zerop (length regexp)))
        (frame (selected-frame))
        (max-length 0)
        faces line-format
        disp-frame window face-name)
    ;; We filter and take the max length in one pass
    (delq nil
          (mapcar (λ (f)
                    (let ((s (symbol-name f)))
                      (when (or all-faces (string-match-p regexp s))
                        (setq max-length (max (length s) max-length))
                        f)))
                  (sort (face-list) #'string-lessp)))))

;; https://stackoverflow.com/questions/884498/how-do-i-intercept-ctrl-g-in-emacs
(defun pen-customize-face (face)
  (interactive
   (let ((inhibit-quit t)
         (hlm (ignore-errors global-hl-line-mode)))
     (if hlm
         (ignore-errors
           (global-hl-line-mode -1)))

     (let ((f))
       ;; with-local-quit always returns nil
       (unless (with-local-quit
                 (setq f (str-or (fz (pen-list-faces)
                                     (if (and
                                          (face-at-point)
                                          (yes-or-no-p "Face at point?"))
                                         (symbol-name
                                          (face-at-point)))
                                     nil
                                     "face: ")
                                 nil)))
         (progn
           (setq quit-flag nil)))
       (if hlm
           (ignore-errors (global-hl-line-mode t)))
       (list f))))
  (if face
      (customize-face (intern face))))

(require 'flyspell)

(defun org-set-heading-height-1 ()
  (interactive)
  (set-face-attribute 'org-document-title nil :height 1.0)
  (set-face-attribute 'org-level-1 nil :height 1.0)
  (set-face-attribute 'org-level-2 nil :height 1.0)
  (set-face-attribute 'org-level-3 nil :height 1.0)
  (set-face-attribute 'org-scheduled-today nil :height 1.0)
  (set-face-attribute 'org-agenda-date-today nil :height 1.1)
  (set-face-attribute 'org-table nil :foreground "#008787"))

(defun pen-set-faces ()
  (interactive)

  (org-set-heading-height-1)

  ;; I must ignore errors for everything or the frame wont even start for workers
  ;; Be careful
  (progn
    (set-face-attribute
     'menu nil
     :inverse-video nil
     :background "#005FAF"
     :foreground "#64b5f6"
     :bold t)

    (set-face-attribute
     'tty-menu-disabled-face nil
     :inverse-video nil
     :background "#1565c0"
     :foreground "lightgray"
     :bold t)

    (set-face-attribute
     'tty-menu-enabled-face nil
     :inverse-video nil
     :background "#1565c0"
     :foreground "#f9a822"
     :bold t)

    (set-face-attribute
     'tty-menu-selected-face nil
     :inverse-video nil
     :background "red"
     :bold t))

  (set-face-attribute
   'mode-line nil
   :inverse-video nil
   :background "#1565c0"
   :foreground "#64b5f6"
   :bold t)

  (set-face-attribute
   'comint-highlight-prompt nil
   :inverse-video nil
   :background "#1565c0"
   :foreground "#64b5f6"
   :bold t)

  (set-face-attribute
   'mode-line-inactive nil
   :inverse-video nil
   :background "#151515"
   :foreground "#646464"
   :bold t)

  (require 'auto-highlight-symbol)
  ;; (global-auto-highlight-symbol-mode -1)
  (global-auto-highlight-symbol-mode 1)
  ;; Keep it at 0.2 so that as I am typing, it doesn't flicker
  (setq ahs-idle-interval 0.2)
  (let ((bg "#151515")
        (fg "#333333"))
    (set-face-attribute
     'ahs-plugin-default-face nil
     :inverse-video nil
     :background bg
     :foreground fg
     :bold t)
    (set-face-attribute
     'ahs-plugin-default-face-unfocused nil
     :inverse-video nil
     :background bg
     :foreground fg
     :bold t)
    (set-face-attribute
     'ahs-face nil
     :inverse-video nil
     :background bg
     :foreground fg
     :bold t)
    (set-face-attribute
     'ahs-face-unfocused nil
     :inverse-video nil
     :background bg
     :foreground fg
     :bold t))

  ;; This doesn't work well with nvc
  ;; (set-face-foreground 'default "#404040")
  (set-face-foreground 'default nil)

  (set-face-foreground 'minibuffer-prompt "#64b5f6")

  (set-face-attribute
   'region nil
   :inverse-video nil
   :background "#903015"
   :foreground "#f66064"
   :bold t)

  (let ((fg "#a73f5f")
        (bg "#331111")
        (wfg "#5555ff")
        (wbg "#222222")
        (cfg "#ffcc00")
        (cbg "#222222")
        (xfg "#ff55ff")
        (xbg "#222222"))

    (require 'lsp-ui)
    (require 'lsp-lens)

    (set-face-attribute
     'lsp-details-face nil
     :height 1.0
     :inherit nil
     :background "#151515"
     :foreground "#222222"
     :bold t)

    (set-face-attribute 'lsp-ui-sideline-symbol nil :box nil)
    (set-face-attribute 'lsp-ui-sideline-current-symbol nil :box nil)
    (set-face-foreground 'lsp-ui-sideline-current-symbol "#66ff66")
    (set-face-background 'lsp-ui-sideline-current-symbol "#000000")
    (set-face-foreground 'lsp-ui-sideline-symbol "#6666ff")
    (set-face-background 'lsp-ui-sideline-symbol "#000000")
    (set-face-foreground 'lsp-ui-sideline-symbol-info "#444444")
    (set-face-foreground 'lsp-ui-sideline-symbol-info "#753505")
    (set-face-foreground 'lsp-ui-peek-filename "#880000")
    (set-face-background 'lsp-ui-peek-filename "#111111")
    (set-face-foreground 'lsp-ui-peek-selection "#448844")
    (set-face-background 'lsp-ui-peek-selection "#222222")
    (set-face-foreground 'lsp-ui-peek-header "#222222")
    (set-face-background 'lsp-ui-peek-header "#111111")
    (set-face-foreground 'lsp-ui-peek-footer "#222222")
    (set-face-background 'lsp-ui-peek-footer "#111111")
    (set-face-foreground 'lsp-ui-peek-highlight "#4444ff")
    (set-face-background 'lsp-ui-peek-highlight "#222222")
    (set-face-foreground 'lsp-ui-sideline-global nil)
    (set-face-background 'lsp-ui-sideline-global nil)

    (require 'transient)
    (set-face-foreground 'transient-unreachable "#333333")
    ;; Hopefully, invisible
    (set-face-foreground 'transient-unreachable-key "#111111")

    (set-face-foreground 'header-line "#253525")
    ;; Keep it dark because the LSP breadcrumb is dark
    (set-face-background 'header-line "#101010")
    ;; (set-face-background 'header-line "#202020")

    (require 'markdown-mode)
    (set-face-attribute 'markdown-header-face nil :height 'unspecified)
    ;; (face-attribute 'markdown-header-face-1 :height)
    ;; (face-attribute 'lsp-headerline-breadcrumb-path-error-face :height)
    (set-face-attribute 'markdown-header-face-1 nil :height 'unspecified)
    (set-face-attribute 'markdown-header-face-2 nil :height 'unspecified)
    (set-face-attribute 'markdown-header-face-3 nil :height 'unspecified)
    (set-face-attribute 'markdown-header-face-4 nil :height 'unspecified)
    (set-face-attribute 'markdown-header-face-5 nil :height 'unspecified)
    (set-face-attribute 'markdown-header-face-6 nil :height 'unspecified)
    ;; (face-all-attributes 'markdown-header-face)
    ;; (face-all-attributes 'markdown-header-face-1)

    (require 'lsp-headerline)
    (set-face-background 'lsp-headerline-breadcrumb-path-error-face nil)
    (set-face-foreground 'lsp-headerline-breadcrumb-path-error-face "#662222")
    (set-face-underline 'lsp-headerline-breadcrumb-path-error-face nil)

    (set-face-background 'lsp-headerline-breadcrumb-path-hint-face nil)
    (set-face-foreground 'lsp-headerline-breadcrumb-path-hint-face "#226622")
    (set-face-underline 'lsp-headerline-breadcrumb-path-hint-face nil)

    (set-face-background 'lsp-headerline-breadcrumb-path-info-face nil)
    (set-face-foreground 'lsp-headerline-breadcrumb-path-info-face "#226622")
    (set-face-underline 'lsp-headerline-breadcrumb-path-info-face nil)

    (set-face-background 'lsp-headerline-breadcrumb-path-warning-face nil)
    (set-face-foreground 'lsp-headerline-breadcrumb-path-warning-face "#666622")
    (set-face-underline 'lsp-headerline-breadcrumb-path-warning-face nil)

    ;; I actually do want it to be dark like this
    (require 'lsp-lens)
    (set-face-foreground 'lsp-lens-face "#222222")
    (set-face-background 'lsp-lens-face "#151515")

    (require 'shr)
    (set-face-foreground 'shr-link fg)
    (set-face-background 'shr-link bg)

    (require 'org-faces)
    (set-face-foreground 'org-link fg)
    (set-face-background 'org-link bg)

    (set-face-background 'font-lock-comment-face nil)
    (set-face-background 'linum nil)
    (set-face-foreground 'line-number "#444444")
    (set-face-background 'line-number "#111111")
    (set-face-foreground 'line-number-current-line "#444444")
    (set-face-background 'line-number-current-line "#1c1c1c")

    (require 'w3m-util)

    (set-face-foreground 'w3m-anchor fg)
    (set-face-background 'w3m-anchor bg)

    (require 'w3m)
    (set-face-foreground 'w3m-current-anchor fg)
    (set-face-background 'w3m-current-anchor bg)

    (set-face-foreground 'w3m-arrived-anchor bg)
    (set-face-background 'w3m-arrived-anchor fg)

    (require 'button)
    (set-face-foreground 'button fg)
    (set-face-background 'button bg)

    (require 'wid-edit)
    (set-face-foreground 'widget-button wfg)
    (set-face-background 'widget-button wbg)

    (require 'custom)

    (require 'cus-edit)
    (set-face-foreground 'custom-button-pressed wfg)
    (set-face-background 'custom-button-pressed wbg)
    (set-face-foreground 'custom-button-pressed-unraised wfg)
    (set-face-background 'custom-button-pressed-unraised wbg)
    (set-face-foreground 'custom-button-unraised wfg)
    (set-face-background 'custom-button-unraised wbg)
    (set-face-foreground 'custom-link cfg)
    (set-face-background 'custom-link cbg)
    (set-face-foreground 'custom-variable-tag cfg)
    (set-face-background 'custom-variable-tag cbg)
    (set-face-foreground 'custom-group-tag cfg)
    (set-face-background 'custom-group-tag cbg)

    (require 'info)
    (require 'info-xref)
    (set-face-foreground 'info-xref xfg)
    (set-face-background 'info-xref xbg)

    (set-face-foreground 'fringe "#111111")
    (set-face-background 'fringe "#000000")

    (require 'popup)
    (set-face-foreground 'popup-menu-face "#aa9922")
    (set-face-background 'popup-menu-face "#111111")
    (set-face-foreground 'popup-menu-selection-face "#111111")
    (set-face-background 'popup-menu-selection-face "#aa9922"))

  (require 'wid-edit)
  (set-face-foreground 'widget-field "#990055")
  (set-face-background 'widget-field "#222222")

  (set-face-stipple 'default nil)
  (set-face-inverse-video 'default nil)
  (set-face-underline 'default nil)
  (set-face-bold 'default t)
  (set-face-attribute 'default nil :weight 'bold)
  (set-font-encoding 'default t)
  (set-face-attribute 'mode-line nil :box '(:line-width 5))
  (set-face-attribute 'mode-line nil :box nil)
  (set-face-attribute 'mode-line-inactive nil :box nil)
  (set-face-attribute 'mode-line-highlight nil :box nil)
  (set-face-foreground 'fringe "#111111")
  (set-face-background 'fringe "#000000")
  (set-face-foreground 'flyspell-incorrect "#cc2222")
  (set-face-background 'flyspell-incorrect "#222222")
  (set-face-underline 'flyspell-incorrect nil)
  (set-face-background 'flyspell-duplicate "#222222")
  (set-face-foreground 'flyspell-duplicate "#cc9922")
  (set-face-underline 'flyspell-duplicate nil)
  (set-face-background 'flycheck-info "#222222")
  (set-face-background 'flycheck-error "#222222")
  (set-face-background 'flycheck-warning "#222222")
  (set-face-underline 'flycheck-info nil)
  (set-face-underline 'flycheck-error nil)
  (set-face-underline 'flycheck-warning nil)
  (custom-set-faces '(lsp-lsp-flycheck-warning-unnecessary-face ((t (:background "#222222" :foreground nil)))))
  (set-foreground-color "#404040")
  (set-background-color "#151515")
  (set-face-foreground 'default "#404040")
  (set-face-background 'default "#151515")
  (set-face-foreground 'vertical-border "#222222")
  ;; No fringe color -- like terminal
  (set-face-background 'fringe nil)

  (set-face-foreground 'org-block "#447744")
  (set-face-background 'org-block "#151515")

  (require 'ement-room)
  (set-face-attribute 'ement-room-membership nil :height 1.0)
  (set-face-attribute 'ement-room-timestamp-header nil :height 1.0)
  (set-face-attribute 'ement-room-reactions nil :height 1.0)
  (set-face-attribute 'ement-room-reactions-key nil :height 1.0)
  (set-face-attribute 'ement-room-wrap-prefix nil :height 1.0)

  (require 'company)
  (set-face-foreground 'company-tooltip-annotation "#d72f4f")
  ;; (set-face-background 'company-tooltip-annotation "#262626")
  (set-face-background 'company-tooltip-annotation nil)

  (require 'ivy)
  (set-face-foreground 'ivy-current-match "#262626")
  (set-face-background 'ivy-current-match "#d72f4f")

  (set-face-background 'ivy-minibuffer-match-face-2 "#562626")
  (set-face-foreground 'ivy-minibuffer-match-face-2 "#d72f4f")

  ;; Especially needed after getting truecolor
  (set-face-foreground 'completions-annotations ;; "#d72f4f"
                       "#2f4fd7")
  (set-face-background 'completions-annotations "#111111")
  (set-face-attribute 'completions-annotations nil :inherit nil)
  (require 'helm)
  (set-face-background 'helm-separator "#262626")
  (set-face-foreground 'helm-separator "#d72f4f")
  (set-face-foreground 'helm-source-header "#262626")
  (set-face-background 'helm-source-header "#d72f4f")

  (set-face-background 'helm-selection "#262626")
  (set-face-foreground 'helm-selection "#d72f4f")

  (require 'avy)
  (setq avy-background t)
  (set-face-background 'avy-background-face nil)
  (set-face-foreground 'avy-background-face "#222222")

  (require 'selectrum)
  (progn
    ;; selectrum-mouse-highlight
    ;; selectrum-quick-keys-match
    ;; selectrum-quick-keys-highlight

    (set-face-foreground 'selectrum-completion-annotation "#262626")
    (set-face-foreground 'selectrum-completion-docsig "#262626")
    (set-face-foreground 'selectrum-current-candidate "#262626")
    (set-face-foreground 'selectrum-group-separator "#262626")
    (set-face-foreground 'selectrum-group-title "#262626")
    ;; (set-face-foreground 'selectrum-quick-keys-highlight "#262626")

    (set-face-background 'selectrum-completion-annotation "#d72f4f")
    (set-face-background 'selectrum-completion-docsig "#d72f4f")
    (set-face-background 'selectrum-current-candidate "#d72f4f")
    (set-face-background 'selectrum-group-separator "#d72f4f")
    (set-face-background 'selectrum-group-title "#d72f4f"))

  (pen-set-text-contrast-from-config))

(advice-add 'pen-set-faces :around #'ignore-errors-around-advice)

;; eww-browser set faces by itself.
;; But this is here for after emacs initially loads.
;; NO, These actually *break* the faces. I must disable these hooks!
;; Or at least, I must disable one of them.
;; That's nuts. which ones?
(defun pen-new-frame-set-faces (frame)
  (with-selected-frame frame
    (pen-set-faces)))
;; (add-hook 'server-after-make-frame-functions 'pen-set-faces)
;; (remove-hook 'server-after-make-frame-functions 'pen-new-frame-set-faces)
;; (add-hook 'after-make-frame-functions 'pen-new-frame-set-faces)
;; (remove-hook 'after-make-frame-functions 'pen-new-frame-set-faces)

;; This is the only place it needs to be, asides from the beginning of the eww function
(add-hook 'after-init-hook 'pen-set-faces)
;; (remove-hook 'after-init-hook 'pen-set-faces)

(defun pen-set-text-contrast-from-config ()
  (interactive)
  (let ((state (pen-rc-test "text_high_contrast")))
    (if state
        (progn
          (set-face-background 'lsp-ui-doc-background "#151515")
          (set-face-foreground 'default "#606060")
          (set-face-foreground 'lsp-headerline-breadcrumb-path-face "#606060")
          (set-face-background 'default "#000000")
          ;; (set-face-background 'powerline-active0 "#000000")
          ;; (set-face-background 'powerline-active1 "#000000")
          ;; (set-face-background 'powerline-active2 "#000000")
          ;; (set-face-background 'powerline-inactive0 "#000000")
          ;; (set-face-background 'powerline-inactive1 "#000000")
          ;; (set-face-background 'powerline-inactive2 "#000000")
          (set-face-background 'line-number "#000000")
          (set-face-background 'window-divider "#000000")
          (set-face-foreground 'window-divider "#000000")
          (set-face-background 'line-number-current-line "#000000")
          (set-face-background 'vertical-border "#000000")
          (set-face-foreground 'vertical-border "#111111")

          ;; This has not had a noticeable effect yet
          (setq helm-frame-background-color "#000000"))
      (progn
        (set-face-background 'lsp-ui-doc-background "#202020")
        (set-face-foreground 'default "#404040")
        (set-face-foreground 'lsp-headerline-breadcrumb-path-face "#222222")
        (set-face-background 'default "#151515")
        ;; (set-face-background 'powerline-active0 "#111111")
        ;; (set-face-background 'powerline-active1 "#111111")
        ;; (set-face-background 'powerline-active2 "#111111")
        ;; (set-face-background 'powerline-inactive0 "#111111")
        ;; (set-face-background 'powerline-inactive1 "#111111")
        ;; (set-face-background 'powerline-inactive2 "#111111")
        (set-face-background 'line-number "#111111")
        (set-face-background 'line-number-current-line "#111111")
        (set-face-background 'vertical-border "#111111")
        (set-face-foreground 'vertical-border "#222222")

        ;; This has not had a noticeable effect yet
        (setq helm-frame-background-color "#151515")))
    state))

(pen-set-faces)

;; (pen-set-text-contrast-from-config)

(define-key pen-map (kbd "M-l M-q M-f") 'pen-customize-face)

(provide 'pen-faces)
