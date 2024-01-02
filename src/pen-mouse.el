(require 'mwheel)

;; mouse tracking seems to work in the terminal anyway
;; especially with tmux next-3.4.
;; But track-mouse appears to actually change the active frame
(setq track-mouse t)
;; (setq track-mouse nil)

;; This breaks from emacs27

(defun mouse-wheel-scroll-more (event)
  "Increase or decrease the height of the default face according to the EVENT."
  (interactive (list last-input-event))
  (mwheel-scroll event)
  (mwheel-scroll event)
  (mwheel-scroll event)
  (mwheel-scroll event)
  (mwheel-scroll event))

(defun mouse-wheel-scroll-2 (event)
  "Increase or decrease the height of the default face according to the EVENT."
  (interactive (list last-input-event))
  (mwheel-scroll event)
  (mwheel-scroll event))

(define-minor-mode mouse-wheel-mode
  "Toggle mouse wheel support (Mouse Wheel mode)."
  :init-value t
  ;; We'd like to use custom-initialize-set here so the setup is done
  ;; before dumping, but at the point where the defcustom is evaluated,
  ;; the corresponding function isn't defined yet, so
  ;; custom-initialize-set signals an error.
  :initialize 'custom-initialize-delay
  :global t
  :group 'mouse
  ;; Remove previous bindings, if any.
  (mouse-wheel--remove-bindings)
  ;; Setup bindings as needed.
  (when mouse-wheel-mode
    (dolist (binding mouse-wheel-scroll-amount)
      (cond
       ;; Bindings for changing font size.
       ((and (consp binding) (eq (cdr binding) 'text-scale))
        (dolist (event (list mouse-wheel-down-event mouse-wheel-up-event))
          (mouse-wheel--add-binding `[,(list (caar binding) event)]
                                    'mouse-wheel-scroll-more)))
       ;; Bindings for scrolling.
       (t
        (dolist (event (list mouse-wheel-down-event mouse-wheel-up-event
                             mouse-wheel-left-event mouse-wheel-right-event))
          (dolist (key (mouse-wheel--create-scroll-keys binding event))
            (mouse-wheel--add-binding key 'mouse-wheel-scroll-2))))))))

(mouse-wheel-mode -1)
(mouse-wheel-mode 1)

;; This aborts once
;; (defvar pen-mouse-abort-set-point nil)

(defun pen-mouse-set-point (event &optional promote-to-region)
  "Move point to the position clicked on with the mouse.
This should be bound to a mouse click event type.
If PROMOTE-TO-REGION is non-nil and event is a multiple-click, select
the corresponding element around point, with the resulting position of
point determined by `mouse-select-region-move-to-beginning'."
  (interactive "e\np")
  (mouse-minibuffer-check event)
  (if (and promote-to-region (> (event-click-count event) 1))
      (progn
        (mouse-set-region event)
        (when mouse-select-region-move-to-beginning
          (when (> (posn-point (event-start event)) (region-beginning))
            (exchange-point-and-mark))))
    ;; Use event-end in case called from mouse-drag-region.
    ;; If EVENT is a click, event-end and event-start give same value.
    (posn-set-point (event-end event))))

;; This is to disable right-click from changing the position when mark is active
(defun mouse-set-point (event &optional promote-to-region)
  (interactive "e\np")
  (try
   (if (or (eq (car event)
               'mouse-1)
           (eq (car event)
               'down-mouse-1)
           (eq (car event)
               'double-mouse-1)
           (eq (car event)
               'double-down-mouse-1)
           (not mark-active))
       (pen-mouse-set-point event promote-to-region))
   (pen-mouse-set-point event promote-to-region)
   t))

(defun right-click-context-click-menu (_event)
  "Open Right Click Context menu by Mouse Click `EVENT'."
  (interactive "e")
  (when (or (eq right-click-context-mouse-set-point-before-open-menu 'always)
            (and (null mark-active)
                 (eq right-click-context-mouse-set-point-before-open-menu 'not-region)))
    (call-interactively #'pen-mouse-set-point))
  (right-click-context-menu))

(defun right-click-context-menu ()
  "Open Right Click Context menu."
  (interactive)
  ;; This should make it so the context menu appears at the top left of the region -- it's better
  (save-excursion-and-region-reliably
   (if (and mark-active
            (< (mark) (point)))
       (exchange-point-and-mark))
   (let ((popup-menu-keymap (copy-sequence popup-menu-keymap)))
     ;; (define-key popup-menu-keymap [mouse-3] #'right-click-context--click-menu-popup)
     (define-key popup-menu-keymap [mouse-3] #'right-click-popup-close)
     (define-key popup-menu-keymap (kbd "C-g") #'right-click-popup-close)
     (let ((value (popup-cascade-menu (right-click-context--build-menu-for-popup-el (right-click-context--menu-tree) nil))))
       (when value
         (if (symbolp value)
             (call-interactively value t)
           (eval value)))))))

(advice-add 'mouse-drag-region :around #'ignore-errors-around-advice)

;; mouse hover over just left of the line numbers - the left edge of the screen
(define-key global-map (kbd "<left-margin> <mouse-movement>") 'ignore)
;; lsp breadcrumbs, for example
(define-key global-map (kbd "<header-line> <mouse-movement>") 'ignore)

(defun cua-scroll-up-2 ()
  (interactive)
  (cua-scroll-up 2))

(defun cua-scroll-down-2 ()
  (interactive)
  (cua-scroll-down 2))

;; For the GUI
(progn
  (define-key global-map (kbd "<wheel-down>") 'cua-scroll-up-2)
  (define-key global-map (kbd "<double-wheel-down>") 'cua-scroll-up-2)
  (define-key global-map (kbd "<triple-wheel-down>") 'cua-scroll-up-2)

  (define-key global-map (kbd "<wheel-up>") 'cua-scroll-down-2)
  (define-key global-map (kbd "<double-wheel-up>") 'cua-scroll-down-2)
  (define-key global-map (kbd "<triple-wheel-up>") 'cua-scroll-down-2))

(provide 'pen-mouse)
