(setq custom-file "$HOME/var/smulliga/source/git/config/emacs/config/pen-custom.el")

(defmacro setface (name spec doc)
  `(custom-set-faces (list ',name
                           ,spec)))

(defmacro defsetface (name spec doc)
  `(progn
     (defface ,name ,spec ,doc)
     (setface ,name ,spec ,doc)))

(defsetface colour-button-face
  '((t :foreground nil
       :background nil
       :weight bold
       :inherit nil
       :underline nil))
  "Face for color buttons. Do not color in.")

(define-button-type 'colour-button 'face 'colour-button-face)

;; Can't seem to figure out how to get button colours working again
;; I have run this file in a vanilla emacs and it doesn't affect the colourful overlays.
;; That means that the button face is not causing the problem
(defun list-colors-print (list &optional callback)
  (let ((callback-fn
           (if callback
               `(lambda (button)
                    (funcall ,callback (button-get button 'color-name))))))
    (dolist (color list)
      (if (consp color)
            (if (cdr color)
                (setq color (sort color (lambda (a b)
                                                  (string< (downcase a)
                                                             (downcase b))))))
          (setq color (list color)))
      (let* ((opoint (point))
               (color-values (color-values (car color)))
               (light-p (>= (apply 'max color-values)
                                (* (car (color-values "white")) .5))))
          (insert (car color))
          (indent-to 22)
          (put-text-property opoint (point) 'face `(:background ,(car color)))
          (put-text-property
           (prog1 (point)
             (insert " ")
             ;; Insert all color names.
             (insert (mapconcat 'identity color ",")))
           (point)
           'face (list :foreground (car color)))
          (insert (propertize " " 'display '(space :align-to (- right 9))))
          (insert " ")
          (insert (propertize
                     (apply 'format "#%02x%02x%02x"
                              (mapcar (lambda (c) (ash c -8))
                                      color-values))
                     'mouse-face 'highlight
                     'help-echo
                     (let ((hsv (apply 'color-rgb-to-hsv
                                           (color-name-to-rgb (car color)))))
                       (format "H:%.2f S:%.2f V:%.2f"
                               (nth 0 hsv) (nth 1 hsv) (nth 2 hsv)))))
          (when callback
          (make-text-button
           opoint (point)
           'follow-link t
           'type 'colour-button
           ;; 'face nil
           ;; 'face 'colour-button-face
           ;; 'face (list :background (car color) :foreground (if light-p "black" "white"))
           'mouse-face (list :background (car color) :foreground (if light-p "black" "white"))
           'color-name (car color)
           'action callback-fn)))
      (insert "\n"))
    (goto-char (point-min))))


(setq custom-search-field nil)
(setq custom-unlispify-tag-names nil)
(setq custom-face-default-form 'selected)

;; this *must* exist. Since "~/" doesn't necessarily exist, I can't use that
;; (setq initial-buffer-choice "~/")
(setq initial-buffer-choice nil)

(defun custom-variable-action (widget &optional event)
  "Show the menu for `custom-variable' WIDGET.
Optional EVENT is the location for the menu."

  ;; if there are options then run that menu by default
  ;; custom-variable-select-option
  (if (and (not (>= (prefix-numeric-value current-prefix-arg) 4))
           (ignore-errors (widget-get (car (widget-get widget :children)) :options)))
      (custom-variable-select-option widget)
    (if (eq (widget-get widget :custom-state) 'hidden)
        (custom-toggle-hide widget)
      (unless (eq (widget-get widget :custom-state) 'modified)
        (custom-variable-state-set widget))
      (custom-redraw-magic widget)
      (let* ((completion-ignore-case t)
	           (answer (widget-choose (concat "Operation on "
					                                  (custom-unlispify-tag-name
					                                   (widget-get widget :value)))
				                            (custom-menu-filter custom-variable-menu
						                                            widget)
				                            event)))
        (if answer
	          (funcall answer widget))))))


(defun custom-variable-select-option (widget)
  "Restore the backup value for the variable being edited by WIDGET.
The value that was current before this operation
becomes the backup value, so you can use this operation repeatedly
to switch between two values."
  ;; (fz (widget-get (car (widget-get widget :children)) :options))
  (let* ((symbol (widget-value widget))
         ;; set function
	       (set (or (get symbol 'custom-set) 'set-default))
	       ;; (value (get symbol 'backup-value))
         (value (list (fz (widget-get (car (widget-get widget :children)) :options))))
	       (comment-widget (widget-get widget :comment-widget))
	       (comment (widget-value comment-widget)))
    (if value
	      (progn
	        (custom-variable-backup-value widget)
	        (custom-push-theme 'theme-value symbol 'user 'set value)
	        (condition-case nil
	            (funcall set symbol (car value))
	          (error nil)))
      (user-error "No backup value for %s" symbol))
    (put symbol 'customized-value (list (custom-quote (car value))))
    (put symbol 'variable-comment comment)
    (put symbol 'customized-variable-comment comment)
    (custom-variable-state-set widget)
    ;; This call will possibly make the comment invisible
    (custom-redraw widget)))


(defset custom-variable-menu
  `(("Set for Current Session" custom-variable-set
     (lambda (widget)
       (eq (widget-get widget :custom-state) 'modified)))
    ;; Note that in all the backquoted code in this file, we test
    ;; init-file-user rather than user-init-file.  This is in case
    ;; cus-edit is loaded by something in site-start.el, because
    ;; user-init-file is not set at that stage.
    ;; https://lists.gnu.org/r/emacs-devel/2007-10/msg00310.html
    ,@(when (or custom-file init-file-user)
	      '(("Save for Future Sessions" custom-variable-save
	         (lambda (widget)
	           (memq (widget-get widget :custom-state)
		               '(modified set changed rogue))))))
    ("Undo Edits" custom-redraw
     (lambda (widget)
       (and (default-boundp (widget-value widget))
	          (memq (widget-get widget :custom-state) '(modified changed)))))
    ("Revert This Session's Customization" custom-variable-reset-saved
     (lambda (widget)
       (memq (widget-get widget :custom-state)
	           '(modified set changed rogue))))
    ,@(when (or custom-file init-file-user)
	      '(("Erase Customization" custom-variable-reset-standard
	         (lambda (widget)
	           (and (get (widget-value widget) 'standard-value)
		              (memq (widget-get widget :custom-state)
			                  '(modified set changed saved rogue)))))))
    ("Set to Backup Value" custom-variable-reset-backup
     (lambda (widget)
       (get (widget-value widget) 'backup-value)))
    ;; ("Select from Options"
    ;;  ;; this runs when you select the option
    ;;  custom-variable-select-option
    ;;  (lambda (widget)
    ;;    ;; this runs when you click the button
    ;;    ;; (btv widget)
    ;;    (get (widget-value widget) 'backup-value)))
    ;; ("Select from Options" custom-variable-edit
    ;;  (lambda (widget)
    ;;    (eq (widget-get widget :custom-form) 'lisp)))
    ("---" ignore ignore)
    ("Add Comment" custom-comment-show custom-comment-invisible-p)
    ("---" ignore ignore)
    ("Show Current Value" custom-variable-edit
     (lambda (widget)
       (eq (widget-get widget :custom-form) 'lisp)))
    ("Show Saved Lisp Expression" custom-variable-edit-lisp
     (lambda (widget)
       (eq (widget-get widget :custom-form) 'edit))))
  "Alist of actions for the `custom-variable' widget.
Each entry has the form (NAME ACTION FILTER) where NAME is the name of
the menu entry, ACTION is the function to call on the widget when the
menu is selected, and FILTER is a predicate which takes a `custom-variable'
widget as an argument, and returns non-nil if ACTION is valid on that
widget.  If FILTER is nil, ACTION is always valid.")

(define-key pen-map (kbd "M-l M-q M-v") 'customize-variable)
(define-key pen-map (kbd "M-l M-q M-g") 'customize-group)

(provide 'pen-custom-conf)