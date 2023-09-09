(require 'todo-mode)

(defset glossary-max-lines-for-entire-buffer-gen 1000)
(defset glossary-overflow-chars 10000)
(defset glossary-idle-time 0.2)

(defvar glossary-files nil)

(defun button-at-point ()
  (button-at (point)))

(defun glossary-window-start ()
  (max 1 (- (window-start) glossary-overflow-chars)))

(defun glossary-window-end ()
  (min (point-max) (+ (window-end) glossary-overflow-chars)))

(defun buttons-collect (&optional face)
  "Collect the positions of visible links in the current `help-mode' buffer."

  (let* ((candidates)
         (p (glossary-window-start))
         (b (button-at p))
         (e (or (and b (button-end b)) p))
         (le e))
    (if (and b (if face (eq (button-get b 'face) face)
                 t))
        (push (cons (button-label b) p) candidates))
    (while (and (setq b (next-button e))
                (setq p (button-start b))
                (setq e (button-end b))
                (< p (glossary-window-end)))
      (if (and b (if face (eq (button-get b 'face) face)
                   t))
          (push (cons (button-label b) p) candidates)
        (progn
          (setq e (+ (button-start b) 1))
          (if (<= e le)
              (setq e (+ 1 le)))
          (setq le e))))
    (nreverse candidates)))

(defun pen-get-ov-properties-here (&optional overlay)
  (interactive (list (button-at-point)))

  (if (not overlay)
      (setq overlay (button-at-point)))

  (if overlay
      (let* ((ps (overlay-properties overlay))
             (λ (- (length ps) 2))
             (a (cl-loop for pen-i in (number-sequence 0 l 2) collect (cons (nth pen-i ps)
                                                                            (nth (+ 1 i) ps)))))
        (if (interactive-p)
            (nbfs (pp-to-string a) nil 'emacs-lisp-mode)
          a))))

(defun button-show-properties-here ()
  (interactive)
  (let ((b (button-at (point))))
    (with-current-buffer (btv `(
                               (action . ,(button-get b 'action))
                               (mouse-action . ,(button-get b 'mouse-action))
                               (face . ,(button-get b 'face))
                               (overlay-props . ,(ignore-errors (pen-get-ov-properties-here)))
                               (mouse-face . ,(button-get b 'mouse-face))
                               (keymap . ,(button-get b 'keymap))
                               (type-of-of-of . ,(button-get b 'type))))
      (emacs-lisp-mode))))

(defun get-button-action ()
  "Get the action of the button at point"
  (interactive)
  (let ((b (button-at (point))))
    (if b
        (button-get b 'action))))

(defun copy-button-action (&optional goto)
  (interactive)
  (let ((f (get-button-action))
        (b (button-at (point))))
    (setq f
          (cond ((eq 'help-button-action f) `(progn (apply ',(button-get b 'help-function)
                                                           ',(button-get b 'help-args))
                                                    nil))
                ((eq 'helpful--navigate f) `(find-file (substring-no-properties ,(button-get b 'path))))
                (t f)))
    (if goto
        (ignore-errors (find-function f)))
    (pen-copy (pp-to-string f))))

(defun goto-button-action ()
  (interactive)
  (copy-button-action t))

(defun button-face-p (button face)
  (if (overlayp button)
      (eq (overlay-get button 'face) face)
    (member face (button-get button 'face))))

(defalias 'overlay-face-p 'button-face-p)

(defun button-face-p-here (face)
  (let ((b (button-at-point)))
    (button-face-p b face)))

(defun pen-next-button (n)
  "Move point to the Nth next button in the table of categories."
  (interactive "p")
  (forward-button n 'wrap 'display-message)
  (and (bolp) (button-at (point))
       ;; Align with beginning of category label.
       (forward-char (+ 4 (length todo-categories-number-separator)))))
(define-key pen-map (kbd "M-j M-n") 'pen-next-button)

(defun pen-previous-button (n)
  "Move point to the Nth previous button in the table of categories."
  (interactive "p")
  (backward-button n 'wrap 'display-message)
  (and (bolp) (button-at (point))
       ;; Align with beginning of category label.
       (forward-char (+ 4 (length todo-categories-number-separator)))))
(define-key pen-map (kbd "M-j M-p") 'pen-previous-button)

(provide 'pen-buttons)