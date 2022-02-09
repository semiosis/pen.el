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

(provide 'pen-buttons)