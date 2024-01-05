(require 'spacemacs-dark-theme)

(defvar pen-black-and-white nil)

(defun fix-spacemacs-dark-theme ()
  (interactive)
  (let ((dirpath
         (f-dirname (locate-library "spacemacs-dark-theme"))))
    (loop for fp in (f-files dirpath)
          collect
          (shell-command "sed -i 's/:weight normal//'" fp))))
(fix-spacemacs-dark-theme)
(load-library "spacemacs-dark-theme")

(load-theme 'spacemacs-dark t)

(defsetface org-bold
  '((t :foreground "#d2268b"
       :background "#2e2e2e"
       ;; :weight bold
       :underline t))
  "Face for org-mode bowld."
  :group 'org-faces)

(defsetface org-italic
  '((t :foreground "#8bd226"
       :background "#2e2e2e"
       ;; :weight normal
       :italic t
       :underline t))
  "Face for org-mode italic."
  :group 'org-faces)

(defsetface org-underline
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       ;; :weight normal
       ;; :italic t
       :underline t))
  "Face for org-mode underline."
  :group 'org-faces)

(defsetface org-strikethrough
  '((t :foreground "#660000"
       ;; :weight normal
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
          (mapcar (lambda (f)
                    (let ((s (symbol-name f)))
                      (when (or all-faces (string-match-p regexp s))
                        (setq max-length (max (length s) max-length))
                        f)))
                  (sort (face-list) #'string-lessp)))))

(defmacro without-hl-line (&rest body)
  ""
  `(let ((inhibit-quit t)
         (hlm (ignore-errors hl-line-mode))
         (ghlm (ignore-errors global-hl-line-mode))
         (hls (ignore-errors auto-highlight-symbol-mode)))
     (if hlm
         (ignore-errors
           (hl-line-mode -1)))
     (if ghlm
         (ignore-errors
           (global-hl-line-mode -1)))
     (if hls
         (ignore-errors
           (auto-highlight-symbol-mode -1)))

     (let ((ret ,@body))

       (if hlm
           (ignore-errors (hl-line-mode t)))
       (if ghlm
           (ignore-errors (global-hl-line-mode t)))
       (if hls
           (ignore-errors (auto-highlight-symbol-mode t)))
       ret)))

;; https://stackoverflow.com/questions/884498/how-do-i-intercept-ctrl-g-in-emacs
(defun pen-customize-face (face)
  (interactive
   (without-hl-line
    (list
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
         (setq quit-flag nil))))))

  (if face
      (if (>= (prefix-numeric-value current-prefix-arg) 4)
          (find-face-definition (intern face))
        (customize-face (intern face)))))

(require 'flyspell)

(defun org-set-heading-height-1 ()
  (interactive)
  (set-face-attribute 'org-document-title nil :height 1.0)
  (set-face-attribute 'org-level-1 nil :height 1.0 :weight 'unspecified)
  (set-face-attribute 'org-level-2 nil :height 1.0 :weight 'unspecified)
  (set-face-attribute 'org-level-3 nil :height 1.0 :weight 'unspecified)
  (set-face-attribute 'org-level-4 nil :height 1.0 :weight 'unspecified)
  (set-face-attribute 'org-level-5 nil :height 1.0 :weight 'unspecified)
  (set-face-attribute 'org-scheduled-today nil :height 1.0)
  (set-face-attribute 'org-agenda-date-today nil :height 1.1)
  (set-face-attribute 'org-table nil :foreground "#008787"))


(require 'shr)
(defun shr-tag-pre (dom)
  (let ((shr-folding-mode 'none)
	    ;; (shr-current-font 'default)
        (shr-current-font 'shr-code))
    (shr-ensure-newline)
    (shr-generic dom)
    (shr-ensure-newline)))

(defun pen-set-all-faces-height-1 ()
  ;; This appears to work well
  (interactive)
  ;; The default face must have an absolute height
  (set-face-attribute 'default nil :height 128
                      ;; :weight 'unspecified

                      ;; Hmm. Make it so the GUI does not use bold faces
                      ;; but the terminal may.
                      ;; Emacs should not decide


                      ;; :foreground "#f664b5"

                      ;; :background "#000000"
                      ;; :foreground "#ffffff"

                      ;; :weight 'bold
                      :weight 'unspecified
                      :family "DejaVu Sans Mono")

  (loop for f in
        (remove 'default (pen-list-faces))
        do
        (progn
          ;; This sets an absolute size
          ;; (set-face-attribute f nil :height 128 :weight 'unspecified)
          ;; This sets a relative size
          (set-face-attribute f nil :height 1.0
                              :weight 'unspecified
                              :family 'unspecified))))

(pen-set-all-faces-height-1)
;; After this runs, I need to disable the future changing of face height
;; One example of where this doesn't cover all faces is org-agenda.
;; When org-agenda runs, org-agenda-date-today is set to a height of 1.1
;; So I need to disable future setting of face height.

;; v +/"^(defun set-face-attribute (face frame &rest args)" "/volumes/home/shane/var/smulliga/source/git/emacs-mirror/emacs/lisp/faces.el"

;; The following seems to work:
(defun internal-set-lisp-face-attribute-around-advice (proc face attr value frame)
  (cond ((eq :height attr) nil)
        ((and (eq :slant attr)
              (eq 'italic value))
         (let ((res (apply proc (list face :bold value frame))))
           res))
        ((and pen-black-and-white
              (or (eq :foreground attr)
                  (eq :backgruond attr))) nil)
        (t
         (let ((res (apply proc (list face attr value frame))))
           res))))
(advice-add 'internal-set-lisp-face-attribute :around #'internal-set-lisp-face-attribute-around-advice)
;; (advice-remove 'internal-set-lisp-face-attribute #'internal-set-lisp-face-attribute-around-advice)

(comment
 (defun set-face-attribute (face frame &rest args)
   "Set attributes of FACE on FRAME from ARGS.
This function overrides the face attributes specified by FACE's face spec.
It is mostly intended for internal use.

If FRAME is a frame, set the FACE's attributes only for that frame.  If
FRAME is nil, set attribute values for all existing frames, as well as
the default for new frames.  If FRAME is t, change the default values
of attributes for new frames.

ARGS must come in pairs ATTRIBUTE VALUE.  ATTRIBUTE must be a valid face
attribute name and VALUE must be a value that is valid for ATTRIBUTE,
as described below for each attribute.

In addition to the attribute values listed below, all attributes can
also be set to the special value `unspecified', which means the face
doesn't by itself specify a value for the attribute.

When a new frame is created, attribute values in the FACE's `defface'
spec normally override the `unspecified' values in the FACE's
default attributes.  To avoid that, i.e. to cause ATTRIBUTE's value
be reset to `unspecified' when creating new frames, disregarding
what the FACE's face spec says, call this function with FRAME set to
t and the ATTRIBUTE's value set to `unspecified'.

Note that the ATTRIBUTE VALUE pairs are evaluated in the order
they are specified, except that the `:family' and `:foundry'
attributes are evaluated first.

The following attributes are recognized:

`:family'

VALUE must be a string specifying the font family
\(e.g. \"Monospace\").

`:foundry'

VALUE must be a string specifying the font foundry,
e.g., \"adobe\".  If a font foundry is specified, wild-cards `*'
and `?' are allowed.

`:width'

VALUE specifies the relative proportionate width of the font to use.
It must be one of the symbols `ultra-condensed', `extra-condensed',
`condensed' (a.k.a. `compressed', a.k.a. `narrow'),
`semi-condensed' (a.k.a. `demi-condensed'), `normal' (a.k.a. `medium',
a.k.a. `regular'), `semi-expanded' (a.k.a. `demi-expanded'),
`expanded', `extra-expanded', or `ultra-expanded' (a.k.a. `wide').

`:height'

VALUE specifies the relative or absolute font size (height of the
font).  An absolute height is an integer, and specifies font height in
units of 1/10 pt.  A relative height is either a floating point
number, which specifies a scaling factor for the underlying face
height; or a function that takes a single argument (the underlying
face height) and returns the new height.  Note that for the `default'
face, you must specify an absolute height (since there is nothing for
it to be relative to).

`:weight'

VALUE specifies the weight of the font to use.  It must be one of
the symbols `ultra-heavy', `heavy' (a.k.a. `black'),
`ultra-bold' (a.k.a. `extra-bold'), `bold',
`semi-bold' (a.k.a. `demi-bold'), `medium', `normal' (a.k.a. `regular',
a.k.a. `book'), `semi-light' (a.k.a. `demi-light'),
`light', `extra-light' (a.k.a. `ultra-light'), or `thin'.

`:slant'

VALUE specifies the slant of the font to use.  It must be one of the
symbols `italic', `oblique', `normal', `reverse-italic', or
`reverse-oblique'.

`:foreground', `:background'

VALUE must be a color name, a string.

`:underline'

VALUE specifies whether characters in FACE should be underlined.
If VALUE is t, underline with foreground color of the face.
If VALUE is a string, underline with that color.
If VALUE is nil, explicitly don't underline.

Otherwise, VALUE must be a property list of the form:

`(:color COLOR :style STYLE)'.

COLOR can be either a color name string or `foreground-color'.
STYLE can be either `line' or `wave'.
If a keyword/value pair is missing from the property list, a
default value will be used for the value.
The default value of COLOR is the foreground color of the face.
The default value of STYLE is `line'.

`:overline'

VALUE specifies whether characters in FACE should be overlined.  If
VALUE is t, overline with foreground color of the face.  If VALUE is a
string, overline with that color.  If VALUE is nil, explicitly don't
overline.

`:strike-through'

VALUE specifies whether characters in FACE should be drawn with a line
striking through them.  If VALUE is t, use the foreground color of the
face.  If VALUE is a string, strike-through with that color.  If VALUE
is nil, explicitly don't strike through.

`:box'

VALUE specifies whether characters in FACE should have a box drawn
around them.  If VALUE is nil, explicitly don't draw boxes.  If
VALUE is t, draw a box with lines of width 1 in the foreground color
of the face.  If VALUE is a string, the string must be a color name,
and the box is drawn in that color with a line width of 1.  Otherwise,
VALUE must be a property list of the following form:

 (:line-width WIDTH :color COLOR :style STYLE)

If a keyword/value pair is missing from the property list, a default
value will be used for the value, as specified below.

WIDTH specifies the width of the lines to draw; it defaults to 1.
If WIDTH is negative, the absolute value is the width of the lines,
and draw top/bottom lines inside the characters area, not around it.
WIDTH can also be a cons (VWIDTH . HWIDTH), which specifies different
values for the vertical and the horizontal line width.
COLOR is the name of the color to use for the box lines, default is
the background color of the face for 3D and `flat-button' boxes, and
the foreground color of the face for the other boxes.
STYLE specifies whether a 3D box should be drawn.  If STYLE
is `released-button', draw a box looking like a released 3D button.
If STYLE is `pressed-button', draw a box that looks like a pressed
button.  If STYLE is nil, `flat-button', or omitted, draw a 2D box.

`:inverse-video'

VALUE specifies whether characters in FACE should be displayed in
inverse video.  VALUE must be one of t or nil.

`:stipple'

If VALUE is a string, it must be the name of a file of pixmap data.
The directories listed in the `x-bitmap-file-path' variable are
searched.  Alternatively, VALUE may be a list of the form (WIDTH
HEIGHT DATA) where WIDTH and HEIGHT are the size in pixels, and DATA
is a string containing the raw bits of the bitmap.  VALUE nil means
explicitly don't use a stipple pattern.

For convenience, attributes `:family', `:foundry', `:width',
`:height', `:weight', and `:slant' may also be set in one step
from an X font name:

`:extend'

VALUE specifies whether the FACE should be extended after EOL.
VALUE must be one of t or nil.

`:font'

Set font-related face attributes from VALUE.
VALUE must be a valid font name or font object.  It can also
be a fontset name.  Setting this attribute will also set
the `:family', `:foundry', `:width', `:height', `:weight',
and `:slant' attributes.

`:inherit'

VALUE is the name of a face from which to inherit attributes, or
a list of face names.  Attributes from inherited faces are merged
into the face like an underlying face would be, with higher
priority than underlying faces.

For backward compatibility, the keywords `:bold' and `:italic'
can be used to specify weight and slant respectively.  This usage
is considered obsolete.  For these two keywords, the VALUE must
be either t or nil.  A value of t for `:bold' is equivalent to
setting `:weight' to `bold', and a value of t for `:italic' is
equivalent to setting `:slant' to `italic'.  But if `:weight' is
specified in the face spec, `:bold' is ignored, and if `:slant'
is specified, `:italic' is ignored."
   (setq args (purecopy args))
   (let ((where (if (null frame) 0 frame))
         (spec args)
         family foundry orig-family orig-foundry)
     ;; If we set the new-frame defaults, this face is modified outside Custom.
     (if (memq where '(0 t))
         (put (or (get face 'face-alias) face) 'face-modified t))
     ;; If family and/or foundry are specified, set it first.  Certain
     ;; face attributes, e.g. :weight semi-condensed, are not supported
     ;; in every font.  See bug#1127.
     (while spec
       (cond ((eq (car spec) :family)
              (setq family (cadr spec)))
             ((eq (car spec) :foundry)
              (setq foundry (cadr spec))))
       (setq spec (cddr spec)))
     (when (or family foundry)
       (when (and (stringp family)
                  (string-match "\\([^-]*\\)-\\([^-]*\\)" family))
         (setq orig-foundry foundry
               orig-family family)
         (unless foundry
           (setq foundry (match-string 1 family)))
         (setq family (match-string 2 family))
         ;; Reject bogus "families" that are all-digits -- those are some
         ;; weird font names, like Foobar-12, that end in a number.
         (when (string-match "\\`[0-9]*\\'" family)
           (setq family orig-family)
           (setq foundry orig-foundry)))
       (when (or (stringp family) (eq family 'unspecified))
         (internal-set-lisp-face-attribute face :family (purecopy family)
                                           where))
       (when (or (stringp foundry) (eq foundry 'unspecified))
         (internal-set-lisp-face-attribute face :foundry (purecopy foundry)
                                           where)))
     (while args
       (unless (memq (car args) '(:family :foundry))
         (internal-set-lisp-face-attribute face (car args)
                                           (purecopy (cadr args))
                                           where))
       (setq args (cddr args))))))

(add-hook 'server-after-make-frame-functions 'pen-set-all-faces-height-1)

(defun eww-set-heading-height-1 ()
  (interactive)

  ;; also, set info heading colours

  ;; inline code
  (cl-loop for face in
           '(shr-code)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#AF005F"
                               :foreground "#f664b5"))
  (cl-loop for face in
           '(info-menu-header)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#ffcccc"
                               :foreground "#772222"))
  (cl-loop for face in
           '(shr-h1
             info-title-1)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#AF5F00"
                               :foreground "#f6b564"))
  (cl-loop for face in
           '(shr-h2
             info-title-2)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#005FAF"
                               :foreground "#64b5f6"))
  (cl-loop for face in
           '(shr-h3
             info-title-3)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#00AF5F"
                               :foreground "#64f6b5"))

  (cl-loop for face in
           '(shr-h4
             info-title-4
             shr-h5
             shr-h6)
           do
           (set-face-attribute face nil :height 1.0 :weight 'unspecified
                               :background "#AF005F"
                               :foreground "#f664b5")))

(defun pen-set-faces ()
  (interactive)

  (org-set-heading-height-1)
  (eww-set-heading-height-1)

  ;; default background and foreground
  (set-foreground-color "#404040")
  ;; (set-background-color "#151515")
  (set-background-color "#101010")

  (set-face-foreground 'trailing-whitespace 'unspecified)
  ;; (set-face-background 'trailing-whitespace "#444477")
  (set-face-background 'trailing-whitespace "#000000")

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

    (require 'helm-lsp)
    (defsetface helm-lsp-container-face
                '((t
                   ;; :height 0.8
                   :inherit shadow))
                "The face used for code lens overlays."
                :group 'helm-lsp)

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
    (progn
      (set-face-attribute 'markdown-header-face nil :height 'unspecified)
      ;; (face-attribute 'markdown-header-face-1 :height)
      ;; (face-attribute 'lsp-headerline-breadcrumb-path-error-face :height)
      (set-face-attribute 'markdown-header-face-1 nil :height 'unspecified)
      (set-face-attribute 'markdown-header-face-2 nil :height 'unspecified)
      (set-face-attribute 'markdown-header-face-3 nil :height 'unspecified)
      (set-face-attribute 'markdown-header-face-4 nil :height 'unspecified)
      (set-face-attribute 'markdown-header-face-5 nil :height 'unspecified)
      (set-face-attribute 'markdown-header-face-6 nil :height 'unspecified))
    (progn
      (set-face-attribute 'markdown-header-face nil :weight 'unspecified)
      ;; (face-attribute 'markdown-header-face-1 :weight)
      ;; (face-attribute 'lsp-headerline-breadcrumb-path-error-face :weight)
      (set-face-attribute 'markdown-header-face-1 nil :weight 'unspecified)
      (set-face-attribute 'markdown-header-face-2 nil :weight 'unspecified)
      (set-face-attribute 'markdown-header-face-3 nil :weight 'unspecified)
      (set-face-attribute 'markdown-header-face-4 nil :weight 'unspecified)
      (set-face-attribute 'markdown-header-face-5 nil :weight 'unspecified)
      (set-face-attribute 'markdown-header-face-6 nil :weight 'unspecified))
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

    (set-face-foreground 'line-number "#444444")
    (set-face-background 'line-number "#111111")

    ;; (set-face-background 'org-block-begin-line "#1c1c1c")
    (set-face-background 'org-block-begin-line nil)
    ;; (set-face-background 'org-block-end-line "#1c1c1c")
    (set-face-background 'org-block-end-line nil)
    ;; (set-face-foreground 'org-block-begin-line "#af5faf")
    ;; (set-face-foreground 'org-block-end-line "#af5faf")
    (set-face-foreground 'org-block-begin-line "#222222")
    (set-face-foreground 'org-block-end-line "#222222")


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
    (set-face-foreground 'info-xref-visited cfg)
    (set-face-background 'info-xref-visited cbg)

    (set-face-foreground 'fringe "#111111")
    (set-face-background 'fringe "#000000")

    (require 'popup)
    (set-face-foreground 'popup-menu-face "#aa9922")
    (set-face-background 'popup-menu-face "#111111")
    (set-face-inverse-video 'popup-menu-selection-face t)
    (set-face-foreground 'popup-menu-selection-face "#aa9922")
    (set-face-background 'popup-menu-selection-face "#111111"))

  (require 'notmuch)

  ;; View in tree mode to get the other view
  ;; (define-key notmuch-tree-mode-map (kbd "C-d") 'notmuch-tree-mode-transient)
  (let ((author_face_fg "#2266ff")
        (author_face_bg "#111111"))
    (set-face-foreground 'notmuch-search-date author_face_fg)
    (set-face-background 'notmuch-search-date author_face_bg)
    (set-face-foreground 'notmuch-tree-match-date-face author_face_fg)
    (set-face-background 'notmuch-tree-match-date-face author_face_bg))

  (set-face-foreground 'notmuch-search-unread-face "#444444")
  (set-face-background 'notmuch-search-unread-face "#111111")
  (set-face-foreground 'notmuch-search-count "#444466")
  (set-face-background 'notmuch-search-count "#111111")

  (set-face-foreground 'notmuch-search-matching-authors "#774477")
  (set-face-background 'notmuch-search-matching-authors "#111111")
  (set-face-foreground 'notmuch-tree-match-author-face "#774477")
  (set-face-background 'notmuch-tree-match-author-face "#111111")

  (set-face-foreground 'notmuch-search-subject "#777777")
  (set-face-background 'notmuch-search-subject "#111111")
  (set-face-foreground 'notmuch-tree-match-subject-face "#777777")
  (set-face-background 'notmuch-tree-match-subject-face "#111111")

  (require 'faces)
  (set-face-attribute 'variable-pitch nil :family 'unspecified)
  (set-face-attribute 'variable-pitch-text nil :height 'unspecified)

  (provide 'shr)
  (set-face-attribute 'shr-text nil :height 'unspecified)

  (require 'cus-edit)
  (set-face-attribute 'custom-visibility nil :height 'unspecified)

  (require 'eww)
  (defsetface eww-cached
              '((t :foreground "#6699cc"
                   :background "#3a3a3a"
                   :weight bold
                   :underline t))
              "Face for cached urls.")

  ;; (set-face-foreground 'eww-form-text "#990055")
  ;; (set-face-background 'eww-form-text "#222222")

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

  (require 'helm-files)
  (set-face-attribute 'helm-ff-prefix nil :weight 'bold)
  (set-face-attribute 'helm-ff-file nil :weight 'bold)
  (set-face-attribute 'helm-ff-executable nil :weight 'bold)

  (require 'avy)
  (setq avy-background t)
  ;; (set-face-background 'avy-background-face nil)
  ;; I need to set also the background.
  ;; Test with info-mode
  (set-face-background 'avy-background-face "#141414")
  (set-face-foreground 'avy-background-face "#222222")

  (require 'magit)
  (require 'magit-log)

  (defsetface magit-blame-dimmed
              '((t :inherit magit-dimmed
                   ;; :weight normal
                   ;; :slant normal
                   ))
              "Face used for the blame margin in some cases when blaming.
Also see option `magit-blame-styles'."
              :group 'magit-faces)

  (defsetface magit-log-date
              '((((class color) (background light))
                 :foreground "grey30"
                 ;; :slant normal
                 ;; :weight normal
                 )
                (((class color) (background  dark))
                 :foreground "grey80"
                 ;; :slant normal
                 ;; :weight normal
                 ))
              "Face for the date part of the log output."
              :group 'magit-faces)

  (defsetface magit-filename
              '((t
                 ;; :weight normal
                 ))
              "Face for filenames."
              :group 'magit-faces)

  (require 'org-faces)
  (set-face-background 'org-scheduled-previously nil)
  (set-face-foreground 'org-scheduled-previously "#222222")

  ;; (set-face-foreground 'org-scheduled-previously "yellow")
  (set-face-italic 'org-scheduled-previously nil)
  ;; (set-face-inverse-video 'org-scheduled-previously nil)

  (require 'display-line-numbers)
  (progn
    (set-face-foreground 'line-number "#262626")
    (set-face-foreground 'line-number-current-line "#444444"))

  (require 'org-faces)
  (progn
    (set-face-foreground 'org-agenda-calendar-event "#999999")
    (set-face-background 'org-agenda-calendar-event nil))
  (progn
    (set-face-foreground 'org-scheduled-previously "#994444")
    (set-face-background 'org-scheduled-previously nil))

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
    (set-face-background 'selectrum-group-title "#d72f4f")))

;; nadvice - proc is the original function, passed in. do not modify
(defun pen-set-faces-around-advice (proc &rest args)
  (let ((res (apply proc args)))
    (pen-set-text-contrast-from-config)
    res))
(advice-add 'pen-set-faces :around #'pen-set-faces-around-advice)
;; (advice-remove 'pen-set-faces #'pen-set-faces-around-advice)

(advice-add 'pen-set-faces :around #'ignore-errors-around-advice)
;; (advice-remove 'pen-set-faces #'ignore-errors-around-advice)

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

;; (toggle-pen-rc "text_high_contrast" t t)
(defun toggle-text-contrast (&optional changestate)
  (interactive)

  (toggle-pen-rc "text_high_contrast" changestate t)

  ;; 0 is a query
  ;; (if (eq 0 changestate)
  ;;     (toggle-pen-rc "text_high_contrast" nil t)
  ;;   (let ((newstate (cond
  ;;                    ((eq -1 changestate) 1)
  ;;                    ((eq 1 changestate) nil)
  ;;                    (t (toggle-pen-rc "text_high_contrast" nil t)))))
  ;;     (toggle-pen-rc
  ;;      "text_high_contrast"
  ;;      (if newstate
  ;;          "off"
  ;;        "on"))
  ;;     (pen-set-text-contrast-from-config)))
  )

(defun pen-set-text-contrast-from-config ()
  (interactive)
  (let ((state (pen-rc-test-early "text_high_contrast")))
    (if state
        (progn
          (set-face-foreground 'default "#606060")
          (set-face-background 'default "#000000")

          (set-face-background 'lsp-ui-doc-background "#151515")
          (set-face-foreground 'lsp-headerline-breadcrumb-path-face "#606060")
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
        (set-face-foreground 'default "#404040")
        (set-face-background 'default "#101010")

        (set-face-background 'lsp-ui-doc-background "#202020")
        (set-face-foreground 'lsp-headerline-breadcrumb-path-face "#222222")
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

(pen-set-text-contrast-from-config)

(define-key pen-map (kbd "M-l M-q M-f") 'pen-customize-face)

;; (defvar testest (pen-list-faces))

(progn
  (cl-loop for f in '(menu
                      tty-menu-disabled-face
                      tty-menu-enabled-face
                      tty-menu-selected-face
                      popup-menu-mouse-face
                      popup-menu-face
                      popup-menu-selection-face)
           do
           (set-face-attribute
            f nil
            :italic t
            :inverse-video nil
            ;; :background 'unspecified
            ;; :foreground 'unspecified
            ))

  (cl-loop for f in '(menu
                      tty-menu-selected-face
                      popup-menu-mouse-face
                      popup-menu-selection-face)
           do
           (set-face-attribute
            f nil
            :inverse-video t)))

;; (cl-loop for f in '(
;;                     ;; menu
;;                     ;; tty-menu-disabled-face
;;                     ;; tty-menu-enabled-face
;;                     ;; tty-menu-selected-face
;;                     popup-menu-mouse-face
;;                     popup-menu-face)
;;          do
;;          (set-face-attribute
;;           f nil
;;           :italic t
;;           ;; :inverse-video t
;;           ;; :background "#f7f7f7"
;;           ;; :foreground "#000000"
;;           ))


(defset pen-use-bold nil)

(defun pen-use-bold-p ()
  (and pen-use-bold
       (not (display-graphic-p))))

(require 'server)

(defun invert-highlight-faces ()
  (interactive)
  (cl-loop for f in '(region iedit-occurrence
                             tty-menu-selected-face
                             popup-menu-mouse-face
                             popup-menu-selection-face
                             helm-selection
                             ivy-highlight-face
                             ivy-current-match

                             avy-lead-face

                             org-agenda-date-weekend-today
                             org-agenda-current-time
                             org-imminent-deadline)
           do
           (set-face-attribute
            f nil
            :inverse-video t
            ;; :background 'unspecified
            ;; :foreground 'unspecified
            ;; This was quite useful!
            ;; :bold (pen-use-bold-p)
            )))

(defun enable-hl-line-mode ()
  (interactive)
  (hl-line-mode 1))

;; This works well for vt100
(defun pen-disable-all-faces ()
  (interactive)

  (setq pen-black-and-white t)

  (global-hl-line-mode -1)
  (add-hook 'dired-mode-hook 'enable-hl-line-mode)

  (advice-remove 'internal-set-lisp-face-attribute #'internal-set-lisp-face-attribute-around-advice)

  ;; (etv (pps (frame-face-alist)))

  ;; This will set a default black/white
  ;; But it's best if I use .Xresources
  ;; Keep them unspecified here
  (let ((class '((class color) (min-colors 89)))
        ;; (bg1 "#262626")
        ;; (base "#b2b2b2")
        (bg1 'unspecified)
        (base 'unspecified))
    (custom-theme-set-faces
     ;; 'spacemacs-light
     'spacemacs-dark
     `(default ((,class (:background ,bg1 :foreground ,base))))))

  ;; Where do these values come from?
  ;; "#b2b2b2" "#262626"
  (cl-loop for fr in (frame-list)
           do
           (set-face-foreground 'default 'unspecified fr)
           (set-face-background 'default 'unspecified fr))

  (setq default-frame-alist
        '(;; (set-background-color "#1e1e1e")
          ;; (set-foreground-color "white")
          ;; (background-color . "#000000")
          ;; (foreground-color . "#f664b5")
          (vertical-scroll-bars)
          (left-fringe . -1)
          (right-fringe . -1)))

  ;; (tv "hi")

  (cl-loop for fr in (frame-list)
           do
           (with-selected-frame fr
             (if (display-graphic-p)
                 (progn
                   (comment
                    (set-foreground-color "#000000")
                    (set-background-color "#ffffff"))

                   (comment
                    (set-foreground-color "#ffffff")
                    (set-background-color "#000000"))

                   (set-foreground-color "#000000")
                   (set-background-color "#ffffff"))
               (progn
                 ;; For the tty, use 'unspecified, because I want to take advantage of rev
                 (comment
                  (set-foreground-color "#000000")
                  (set-background-color 'unspecified))

                 (set-foreground-color 'unspecified)
                 ;; (set-background-color "#000000")
                 (set-background-color 'unspecified)

                 ;; tty-menu-enabled-face
                 ))))

  (cl-loop for fr in (frame-list)
           do
           (with-selected-frame fr
             (set-face-bold 'default (pen-use-bold-p) fr)))

  ;; (set-foreground-color 'unspecified)
  ;; (set-background-color 'unspecified)

  ;; avy-lead-face
  ;; avy-lead-face-0
  ;; avy-lead-face-1
  ;; avy-lead-face-2

  ;; j:invert-highlight-faces
  (cl-loop for f in '(region iedit-occurrence

                             ivy-highlight-face
                             ivy-current-match

                             popup-menu-face

                             ebdb-person-name

                             line-number

                             font-lock-keyword-face

                             company-tooltip-selection
                             company-tooltip-common-selection

                             diredfl-dir-heading

                             notmuch-message-summary-face
                             message-header-subject
                             message-header-to
                             message-header-other
                             message-mml

                             org-block

                             epe-git-face
                             epe-symbol-face
                             epe-sudo-symbol-face

                             ;; font-lock-keyword-face

                             ;; window-divider
                             ;; window-divider-first-pixel
                             ;; window-divider-last-pixel

                             minibuffer-prompt

                             evil-ex-substitute-replacement

                             bible-verse-ref-notes

                             org-hide
                             org-level-1
                             org-level-2
                             org-level-3
                             org-level-4
                             org-level-5

                             ;; org-verbatim

                             message-header-name

                             mode-line-active

                             lsp-ui-doc-background
                             lsp-ui-doc-header

                             link

                             ;; main menu bar face
                             menu

                             epe-dir-face

                             fringe

                             tty-menu-enabled-face
                             tty-menu-disabled-face

                             consult-grep-context

                             ;; helm-grep-cmd-line
                             ;; helm-grep-file
                             ;; helm-grep-finish
                             ;; helm-grep-lineno
                             helm-grep-match
                             ivy-grep-info
                             ivy-grep-line-number

                             ivy-current-match
                             ivy-match-required-face
                             ivy-minibuffer-match-face-1
                             ivy-minibuffer-match-face-2
                             ivy-minibuffer-match-face-3
                             ivy-minibuffer-match-face-4
                             ivy-minibuffer-match-highlight
                             ivy-prompt-match


                             ;; wgrep-delete-face
                             ;; wgrep-done-face
                             ;; wgrep-face
                             ;; wgrep-file-face
                             ;; wgrep-reject-face


                             ;; git-gutter+-unchanged
                             ;; git-gutter+-modified
                             ;; git-gutter+-separator
                             ;; git-gutter+-added
                             ;; git-gutter+-deleted
                             ;; git-gutter+-commit-header-face

                             helm-selection

                             hc-tab
                             hc-hard-hyphen
                             hc-hard-space
                             hc-other-char
                             hc-tab
                             hc-trailing-whitespace

                             hl-line

                             magit-diff-file-heading-highlight
                             magit-diff-removed-highlight

                             ;; Highlight is the face for moving cursur over a button
                             highlight

                             lsp-ui-peek-header
                             lsp-ui-peek-footer
                             lsp-ui-peek-selection
                             lsp-ui-peek-highlight

                             avy-lead-face

                             org-agenda-date-weekend-today
                             org-agenda-current-time
                             org-imminent-deadline)
           do
           (set-face-attribute
            f nil
            :inverse-video t
            :background 'unspecified
            :foreground 'unspecified
            ;; This was quite useful!
            :italic nil
            ;; :bold (pen-use-bold-p)
            ))

  ;; ALL FACES
  (loop for fr in (frame-list)
        do
        (progn
          (set-face-background 'default 'unspecified fr)
          (set-face-foreground 'default 'unspecified fr)
          ;; (set-face-foreground 'default "#ffffff" fr)

          (loop for f in
                (pen-list-faces)
                do
                (progn
                  (set-face-background f 'unspecified fr)
                  (set-face-foreground f 'unspecified fr)
                  (set-face-attribute
                   f fr
                   :box nil
                   ;; This was quite useful!
                   :bold (pen-use-bold-p))
                  (if (eq
                       (face-attribute f :slant fr)
                       'italic)
                      (set-face-attribute f fr
                                          :italic nil
                                          :inverse-video t)
                    ;; (set-face-attribute f fr
                    ;;                       :italic nil
                    ;;                       :inverse-video nil)
                    )))))

  ;;
  (cl-loop for f in '(tty-menu-selected-face

                      widget-button

                      lsp-ui-peek-peek

                      ;; hc-tab
                      ;; font-lock-keyword-face

                      ;; lsp-headerline-breadcrumb-path-face

                      ;; macrostep-expansion-highlight-face

                      git-gutter+-unchanged
                      git-gutter+-modified
                      git-gutter+-separator
                      git-gutter+-added
                      git-gutter+-deleted
                      git-gutter+-commit-header-face

                      ;; org-verbatim

                      popup-menu-mouse-face
                      popup-menu-selection-face)
           do
           (set-face-attribute
            f nil
            ;; :inverse-video nil

            :inverse-video nil

            ;; As beautiful as italic is, it messes with :inverse
            ;; Because when on 2 colours, and italic is enabled, inverse is enabled
            :italic nil
            ;; :background 'unspecified
            ;; :foreground 'unspecified
            ;; :foreground "#000000"
            ;; :background "#ffffff"
            ;; :italic t
            ;; :bold (pen-use-bold-p)
            ))

  (cl-loop for fr in (frame-list)
           do

           (cl-loop for f in '(org-verbatim
                               org-bold
                               bible-verse-ref)
                    do
                    (set-face-attribute
                     f fr
                     :inverse-video nil
                     :overline nil
                     :underline t
                     :box nil
                     :strike-through nil
                     :slant 'italic

                     ;; :italic t
                     )))

  ;; [[customize-variable:-whitespace-style]]
  (setq whitespace-style
        '(trailing tabs tab-mark)
        ;; '(trailing tabs tab-mark empty space-after-tab::tab space-after-tab::space space-after-tab space-before-tab::tab space-before-tab::space space-before-tab)
        )

  (loop for fr in (frame-list)
        do
        (cl-loop for f in '(;; widget-button
                            hc-trailing-whitespace

                            ;; lsp-ui-peek-peek

                            lsp-headerline-breadcrumb-path-face


                            hc-trailing-whitespace
                            trailing-whitespace
                            whitespace-trailing
                            font-lock-comment-face
                            info-code-face

                            whitespace-big-indent
                            whitespace-empty
                            whitespace-hspace
                            whitespace-indentation
                            whitespace-line
                            whitespace-missing-newline-at-eof
                            whitespace-newline
                            whitespace-space
                            whitespace-space-after-tab
                            whitespace-space-before-tab
                            whitespace-tab
                            whitespace-trailing)
                 do
                 (set-face-attribute
                  f fr

                  ;; ideally, but it doesn't seem to work well
                  ;; but I'll use it anyway.
                  ;; :inverse-video nil
                  ;; :foreground "#ffffff"
                  ;; :background "#000000"

                  ;; Otherwise, use this method
                  :inverse-video t
                  :foreground 'unspecified
                  :background 'unspecified)))

  (loop for fr in (frame-list)
        do
        (progn
          (set-face-foreground 'default 'unspecified)
          (set-face-background 'default 'unspecified)))

  ;; OK, so where does it get #b2b2b2 for default?

  (advice-add 'pen-set-faces :around #'around-advice-disable-function)
  (advice-add 'pen-set-text-contrast-from-config :around #'around-advice-disable-function)
  (advice-add 'minibuffer-bg :around #'around-advice-disable-function)

  ;; server-after-make-frame-hook
  (if (not (member 'pen-disable-all-faces server-after-make-frame-hook))
      (add-hook-last 'server-after-make-frame-hook 'pen-disable-all-faces))

  ;; (add-hook-last 'after-setting-font-hook 'pen-disable-all-faces)

  ;; (snc "win vt100-tmux")

  (advice-add 'internal-set-lisp-face-attribute :around #'internal-set-lisp-face-attribute-around-advice))

(comment
 (add-hook 'minibuffer-setup-hook
           (lambda ()
             (make-local-variable 'face-remapping-alist)
             (add-to-list 'face-remapping-alist '(default (:inverse-video t)))))
 (remove-hook 'minibuffer-setup-hook
              (lambda ()
                (make-local-variable 'face-remapping-alist)
                (add-to-list 'face-remapping-alist '(default (:inverse-video t))))))

(defun around-advice-disable-function (proc &rest args)
  nil)

;; (advice-remove 'pen-set-faces #'around-advice-disable-function)

(defvar pen-disable-faces-minor-mode-map (make-sparse-keymap)
  "Keymap for `pen-disable-faces-minor-mode'.")

;;;###autoload
(define-minor-mode pen-disable-faces-minor-mode
  "A minor mode for Pen.el disable-facess."
  :lighter " b&w"
  :keymap pen-disable-faces-minor-mode-map)

;;;###autoload
(define-globalized-minor-mode global-pen-disable-faces-minor-mode pen-disable-faces-minor-mode pen-disable-faces-minor-mode)

(global-pen-disable-faces-minor-mode t)

(defun show-all-face-colors ()
  (interactive)
  ;; (frame-list)
  (ifietv
   (cl-loop for fr in (frame-list)
            collect
            (list fr
                  (-filter (lambda (e) (second e))
                           (cl-loop for f in (pen-list-faces)
                                    collect
                                    (list f (face-foreground f fr))))))))

(defun show-all-face-weights ()
  (interactive)
  ;; (frame-list)
  (ifietv
   (cl-loop for fr in (frame-list)
            collect
            (list fr
                  (-filter (lambda (e) (second e))
                           (cl-loop for f in (pen-list-faces)
                                    collect
                                    (list f (face-bold-p f fr))))))))

;; TODO Add this to context functions
;; (eq (face-at-point) 'info-code-face)

(defun pen-face-at-point ()
  (without-hl-line
   (face-at-point)))

(defun go-to-start-of-face (&optional face)
  (setq face (or face (face-at-point)))
  (while (and
          (not (bobp))
          (backward-char 1)
          (eq (face-at-point) face))))

(defun go-to-end-of-face (&optional face)
  (setq face (or face (face-at-point)))
  ;; (next-single-property-change )
  (while (and
          (not (eobp))
          (forward-char 1)
          (eq (face-at-point) face))))

(defun select-font-lock-face-region ()
  "Make something to select consecutively syntax-highlighted text
- go backwards until the face changes
- go forwards until the face changes"
  (interactive)
  (without-hl-line
   (let ((block-face (face-at-point))
         (initial-point (point)))

     (go-to-start-of-face block-face)
     (forward-char 1)
     (mark)

     (goto-char initial-point)

     (go-to-end-of-face block-face)
     (backward-char 1)))

  ;; (when (eq (face-at-point) 'font-lock-keyword-face)
  ;;   (set-mark (point))
  ;;   (while (eq (face-at-point) 'font-lock-keyword-face)
  ;;     (forward-char 1)))
  )

(provide 'pen-faces)
