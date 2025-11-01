;; [[ll:wid-edit]]

;; mx:ll

;; [[pa:wid-edit]]

;; (defun pen-locate-libary (name)
;;   (interactive (list (read-string-hist "pen-locate-libary query: ")))

;;   ;; (fz (locate-library name t nil t))

;;   (pen-goto-package-all name))

;; (defalias 'll 'locate-library)
(defalias 'll 'pen-goto-package-all)

(defun widget-at-point (&optional p)
  (if (not p)
      (setq p (point)))
  (widget-at p))

;; v +/"(defun widget-get-action (widget &optional event)" "$EMACSD/config/my-right-click-context.el"

(defun push-widget ()
  (interactive)
  (widget-button-press (point)))

(defmacro buffer-tv (&rest body)
  "Captures inserts, and opens in a tv"

  (cl-letf (((symbol-function 'insert)
             (lambda ())))
    (ignore-errors (aggressive-indent-indent-defun l r)))

  (new-buffer-from-o o))
(defalias 'btv 'buffer-tv)

;; (widget-get (widget-at-point) :options)
(defun widget-show-properties-here ()
  (interactive)
  (with-current-buffer (etv (plist-get-keys (widget-at (point))))
    (emacs-lisp-mode)))

(defun widget-get-action (widget &optional event)
  ""
  (let ((a (widget-get widget :action)))
    (if (eq a 'widget-parent-action)
        (widget-get-action (widget-get widget :parent))
      a)))

(defun copy-widget-action ()
  (interactive)
  (xc (let ((button (get-char-property (point) 'button)))
        (if button
            (widget-get-action button)
          (lookup-key widget-global-map (this-command-keys))))))

(defun goto-widget-action ()
  (interactive)
  (find-function (let ((button (get-char-property (point) 'button)))
                   (if button
                       (widget-get-action button)
                     (lookup-key widget-global-map (this-command-keys))))))

(defun widget-delete-button-action-here ()
  (interactive)
  (widget-delete-button-action (widget-at (point))))

(defun widget-insert-button-action-here ()
  (interactive)
  (widget-insert-button-action (widget-at (point))))

;; TODO Finish
(defset widget-insert-or-remove-button-keymap
        (let ((map (copy-keymap widget-keymap)))
    ;; Only bind mouse-2, since mouse-1 will be translated accordingly to
    ;; the customization of `mouse-1-click-follows-link'.
    ;; (define-key map [down-mouse-1] (lookup-key widget-global-map [down-mouse-1]))
    ;; (define-key map [down-mouse-2] 'widget-button-click)
    ;; (define-key map [mouse-2] 'widget-button-click)
    (define-key map (kbd "-") 'widget-delete-button-action-here)
    (define-key map (kbd "+") 'widget-insert-button-action-here)
    ;; (define-key map (kbd "M-j M--") 'widget-delete-button-action-here)
    ;; (define-key map (kbd "M-+") 'widget-insert-button-action-here)
    map))

(define-widget 'insert-or-remove-button 'push-button
  "A pushable button."
  ;; :button-prefix "["
  ;; :button-suffix "]"
  :button-prefix ""
  :button-suffix ""
  :value-create 'widget-push-button-value-create
  ;; :format "%[%v%]"
  :format "%[%v%]"
  :keymap widget-insert-or-remove-button-keymap
  ;; :format "%v"
  )

(define-widget 'insert-button 'insert-or-remove-button
  "An insert button for the `editable-list' widget."
  ;; :tag "I"
  ;; :tag "⁺¹"
  ;; :tag "+↗"
  ;; :tag "🆕"
  :tag "+"

  ;; :button-prefix 'widget-push-button-prefix
  ;; :button-suffix 'widget-push-button-suffix
  :help-echo (lambda (widget)
               (if (widget-get (widget-get widget :parent) :last-deleted)
                   "Insert back the last deleted item from this list, at this position."
                 "Insert a new item into the list at this position."))
  :action 'widget-insert-button-action)

;; This actually needs to be fixed to land the cursor on the next remove button if there is one
;; mx:widget-example
(define-widget 'delete-button 'insert-or-remove-button
  "A delete button for the `editable-list' widget."
  ;; :tag "R"
  ;; :tag "₋₁"
  ;; :tag "✗"
  ;; https://www.compart.com/en/unicode/block/U+2400
  ;; :tag "␡"
  :tag "-"
  :help-echo "Delete this item from the list, saving it for later reinsertion."
  :action 'widget-delete-button-action)

;; (setq widget-link-prefix "[")

(setq widget-push-button-prefix "[")
(setq widget-push-button-suffix "]")

(defun widget-push-button-value-create (widget)
  "Insert text representing the `on' and `off' states."
  (let* ((tag (or (substitute-command-keys (widget-get widget :tag))
		          (widget-get widget :value)))
	     (tag-glyph (widget-get widget :tag-glyph))
         ;; INS and DEL buttons still use this
         ;; This is how it should be.
         ;; Guess this is a bugfix
	     (text (concat (widget-get widget :button-prefix)
		               tag
                       (widget-get widget :button-suffix))))
    (if tag-glyph
	(widget-image-insert widget text tag-glyph)
    (insert text))))

;; TODO Make a right-click option to get the widget value
(defun pen-widget-get-value-at-point (&optional p)
  (interactive)
  (setq p (or p (point)))
  (let* ((w (widget-at p))
         (val (if w (widget-value w))))
    (if val
        (if (interactive-p)
            (xc val)
          val))))

;; (show-map (widget-get (widget-at (point)) :keymap))
(defun pen-widget-show-keymap-at-point (&optional p)
  (interactive)
  (setq p (or p (point)))
  (let* ((w (widget-at p))
         (val (if w (widget-get w :keymap))))
    (if val
        (if (interactive-p)
            (show-map val)
          val))))

(define-key widget-keymap (kbd "M-p") 'widget-backward)
(define-key widget-keymap (kbd "M-n") 'widget-forward)

;; This from pa:cus-edit is what set the keymap for the editable text fields.
;; Now I just need to get the keymap working for the buttons
;; (widget-put (get 'editable-field 'widget-type) :keymap custom-field-keymap)

;; This fixed it
;; (widget-put (get 'insert-button 'widget-type) :keymap widget-insert-or-remove-button-keymap)
;; (widget-put (get 'delete-button 'widget-type) :keymap widget-insert-or-remove-button-keymap)



(provide 'pen-widgets)
