;; Seems broken, but don't know how to fix it, so I'll just make my own
(comment
 (progn
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

   (defun list-colors-display (&optional list buffer-name callback)
     "Display names of defined colors, and show what they look like.
If the optional argument LIST is non-nil, it should be a list of
colors to display.  Otherwise, this command computes a list of
colors that the current display can handle.  Customize
`list-colors-sort' to change the order in which colors are shown.
Type `g' or \\[revert-buffer] after customizing `list-colors-sort'
to redisplay colors in the new order.

If the optional argument BUFFER-NAME is nil, it defaults to *Colors*.

If the optional argument CALLBACK is non-nil, it should be a
function to call each time the user types RET or clicks on a
color.  The function should accept a single argument, the color name."
     (interactive)
     (when (and (null list) (> (display-color-cells) 0))
       (setq list (list-colors-duplicates (defined-colors)))
       (when list-colors-sort
         ;; Schwartzian transform with `(color key1 key2 key3 ...)'.
         (setq list (mapcar
		             'car
		             (sort (delq nil (mapcar
				                      (lambda (c)
				                        (let ((key (list-colors-sort-key
						                            (car c))))
				                          (when key
					                        (cons c (if (consp key) key
						                              (list key))))))
				                      list))
			               (lambda (a b)
			                 (let* ((a-keys (cdr a))
				                    (b-keys (cdr b))
				                    (a-key (car a-keys))
				                    (b-key (car b-keys)))
			                   ;; Skip common keys at the beginning of key lists.
			                   (while (and a-key b-key (equal a-key b-key))
			                     (setq a-keys (cdr a-keys) a-key (car a-keys)
				                       b-keys (cdr b-keys) b-key (car b-keys)))
			                   (cond
			                    ((and (numberp a-key) (numberp b-key))
			                     (< a-key b-key))
			                    ((and (stringp a-key) (stringp b-key))
			                     (string< a-key b-key)))))))))
       (when (memq (display-visual-class) '(gray-scale pseudo-color direct-color))
         ;; Don't show more than what the display can handle.
         (let ((lc (nthcdr (1- (display-color-cells)) list)))
	       (if lc
	           (setcdr lc nil)))))
     (unless buffer-name
       (setq buffer-name "*Colors*"))
     (with-help-window buffer-name
       (with-current-buffer standard-output
         (erase-buffer)
         (list-colors-print list callback)
         (set-buffer-modified-p nil)
         (setq truncate-lines t)
         (setq-local list-colors-callback callback)
         (setq revert-buffer-function 'list-colors-redisplay)))
     (when callback
       (pop-to-buffer buffer-name)
       (message "Click on a color to select it.")))))

(defun hex-preceeding-zero (c)
  (if (eq 1 (length c))
      (concat "0" c)
    c))

(defun list-colors-display-24bit (&optional list buffer-name callback)
  (interactive)
  (if (buffer-exists "*Colors*")
      (kill-buffer "*Colors*"))

  (let ((b (new-buffer-from-string ""))
        (per_line (- (/ (window-width) 8)
                     1))
        (resolution 16)
        (i 1))
    (with-current-buffer b
      (rename-buffer "*Colors*")

      (font-lock-mode 1)

      (cl-loop
       for r from 7 to 255 by resolution
       do
       (progn
         (cl-loop
          for g from 7 to 255 by resolution
          do
          (progn
            (cl-loop
             for b from 7 to 255 by resolution

             do
             (let* ((start (point))
                    (end)
                    (rh (hex-preceeding-zero (format "%x" r)))
                    (gh (hex-preceeding-zero (format "%x" g)))
                    (bh (hex-preceeding-zero (format "%x" b)))
                    (color (concat "#" rh gh bh)))

               (insert (concat color " "))
               (if (eq 0 (mod i per_line))
                   (insert "\n"))
               (setq end (point))
               (put-text-property start end 'font-lock-face `(:foreground ,color))
               (setq i (+ 1 i))))
            ;; (insert "\n")
            ;; (insert "\n")
            ))
         ;; (insert "\n")
         ))

      ;; (setq truncate-lines nil)

      (read-only-mode t)

      ;; (use-local-map (copy-keymap foo-mode-map))

      
      ;; (local-set-key "q" 'kill-current-buffer)
      ;; (local-set-key "d" 'kill-current-buffer)

      (beginning-of-buffer))
    (switch-to-buffer b)))

(provide 'pen-colors)
