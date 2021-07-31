(require 'popup)
(require 'right-click-context)

;; Configure the right click menu to have more height
(defset popup-max-height 30)
(cl-defun popup-menu* (list
                       &key
                       point
                       (around t)
                       (width (popup-preferred-width list))
                       (height popup-max-height)
                       max-width
                       margin
                       margin-left
                       margin-right
                       scroll-bar
                       symbol
                       parent
                       parent-offset
                       cursor
                       (keymap popup-menu-keymap)
                       (fallback 'popup-menu-fallback)
                       help-delay
                       nowait
                       prompt
                       isearch
                       (isearch-filter 'popup-isearch-filter-list)
                       (isearch-cursor-color popup-isearch-cursor-color)
                       (isearch-keymap popup-isearch-keymap)
                       isearch-callback
                       initial-index
                       &aux menu event)
  "Show a popup menu of LIST at POINT. This function returns a
value of the selected item. Almost all arguments are the same as in
`popup-create', except for KEYMAP, FALLBACK, HELP-DELAY, PROMPT,
ISEARCH, ISEARCH-FILTER, ISEARCH-CURSOR-COLOR, ISEARCH-KEYMAP, and
ISEARCH-CALLBACK.

If KEYMAP is a keymap which is used when processing events during
event loop.

If FALLBACK is a function taking two arguments; a key and a
command. FALLBACK is called when no special operation is found on
the key. The default value is `popup-menu-fallback', which does
nothing.

HELP-DELAY is a delay of displaying helps.

If NOWAIT is non-nil, this function immediately returns the menu
instance without entering event loop.

PROMPT is a prompt string when reading events during event loop.

If ISEARCH is non-nil, do isearch as soon as displaying the popup
menu.

ISEARCH-FILTER is a filtering function taking two arguments:
search pattern and list of items. Returns a list of matching items.

ISEARCH-CURSOR-COLOR is a cursor color during isearch. The
default value is `popup-isearch-cursor-color'.

ISEARCH-KEYMAP is a keymap which is used when processing events
during event loop. The default value is `popup-isearch-keymap'.

ISEARCH-CALLBACK is a function taking one argument.  `popup-menu'
calls ISEARCH-CALLBACK, if specified, after isearch finished or
isearch canceled. The arguments is whole filtered list of items.

If `INITIAL-INDEX' is non-nil, this is an initial index value for
`popup-select'. Only positive integer is valid."
  (and (eq margin t) (setq margin 1))
  (or margin-left (setq margin-left margin))
  (or margin-right (setq margin-right margin))
  (if (and scroll-bar
           (integerp margin-right)
           (> margin-right 0))
      ;; Make scroll-bar space as margin-right
      (cl-decf margin-right))
  (setq menu (popup-create point width height
                           :max-width max-width
                           :around around
                           :face 'popup-menu-face
                           :mouse-face 'popup-menu-mouse-face
                           :selection-face 'popup-menu-selection-face
                           :summary-face 'popup-menu-summary-face
                           :margin-left margin-left
                           :margin-right margin-right
                           :scroll-bar scroll-bar
                           :symbol symbol
                           :parent parent
                           :parent-offset parent-offset))
  (unwind-protect
      (progn
        (popup-set-list menu list)
        (if cursor
            (popup-jump menu cursor)
          (popup-draw menu))
        (when initial-index
          (dotimes (_i (min (- (length list) 1) initial-index))
            (popup-next menu)))
        (if nowait
            menu
          (popup-menu-event-loop menu keymap fallback
                                 :prompt prompt
                                 :help-delay help-delay
                                 :isearch isearch
                                 :isearch-filter isearch-filter
                                 :isearch-cursor-color isearch-cursor-color
                                 :isearch-keymap isearch-keymap
                                 :isearch-callback isearch-callback)))
    (unless nowait
      (popup-delete menu))))

;; Example
(defun gpt-test-haskell ()
  (let ((lang
         (pen-detect-language (pen-selected-text))))
    (message (concat "Language:" lang))
    (istr-match-p "Haskell" (message lang))))

(setq right-click-context-global-menu-tree
      `(("Cancel" :call identity)
        ("pen: translate" :call pf-translate-from-world-language-x-to-y)
        ("pen: transpile" :call pf-transpile-from-programming-language-x-to-y)
        ("pen (prose)"
         ("pick up line" :call pen-tutor-mode-assist :if (derived-mode-p 'prog-mode))
         ("translate" :call pf-translate-from-world-language-x-to-y)
         ("tldr" :call pf-tldr-summarization :if (selected-p))
         ("eli5" :call pf-eli5-explain-like-i-m-five :if (selected-p))
         ("correct grammar" :call pf-correct-grammar :if (selected-p))
         ("correct grammar 2" :call pf-correct-grammar-2 :if (selected-p))
         ("vexate" :call pf-complicated-explanation-of-how-to-x :if (selected-p))
         ("correct English spelling and grammar" :call pf-correct-english-spelling-and-grammar :if (selected-p)))
        ("pen (code)"
         ("asktutor" :call pen-tutor-mode-assist :if (derived-mode-p 'prog-mode))
         ("transpile" :call pf-transpile-from-programming-language-x-to-y)
         ("add comments" :call pf-annotate-code-with-commentary))))

(provide 'pen-right-click-menu)