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

(provide 'pen-widgets)
