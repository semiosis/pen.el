(require 's)

(defun current-major-mode-map ()
  (let ((sym (intern (concat (current-major-mode-string) "-map"))))
    (if (not (boundp sym))
        (setq sym (intern (concat (s-chop-suffix "-mode" (current-major-mode-string)) "-map"))))
    (if (not (boundp sym))
        (setq sym nil))
    sym))

(defun showmap--read-symbol (prompt predicate)
  (let* ((sym-here (current-major-mode-map) ;; (symbol-at-point)
                   )
         (default-val
           (when (funcall predicate sym-here)
             (symbol-name sym-here))))
    (when default-val
      (setq prompt
            (replace-regexp-in-string
             (rx ": " eos)
             (format " (default: %s): " default-val)
             prompt)))
    (intern (completing-read prompt obarray
                             predicate t nil nil
                             default-val))))

(defmacro variable-name-re-p (re)
  "Predicate for a variable with name matching regex"
  `(lambda (object)
       (and (variable-p object)
            (not (not (string-match-p ,re (symbol-name object)))))))

(defun show-map-as-string (&optional mapsym)
  (interactive (list(showmap--read-symbol "map: " (variable-name-re-p "-map$"))))

  (if (not mapsym)
      (setq mapsym (current-major-mode-map)))

  (if (stringp mapsym)
      (setq mapsym (eval (intern (mapsym)))))

  (let ((mstring (concat "\\{" (symbol-name mapsym) "}")))
    (substitute-command-keys mstring)))

(defun fz-map-fn (&optional mapsym)
  "fuzzy find maps and pretty print them in a new buffer"
  (interactive (list (showmap--read-symbol "map: " (variable-name-re-p "-map$"))))

  (if (not mapsym)
      (setq mapsym (current-major-mode-map)))

  (if (stringp mapsym)
      (setq mapsym (eval (intern (mapsym)))))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (show-map mapsym)
    (let ((prefix-numeric-value nil))
      (run-major-mode-function mapsym))))

(defun show-map (&optional mapsym)
  "fuzzy find maps and pretty print them in a new buffer"
  (interactive (list (showmap--read-symbol "map: " (variable-name-re-p "-map$"))))

  (if (not mapsym)
      (setq mapsym (current-major-mode-map)))

  (if (stringp mapsym)
      (setq mapsym (eval (intern (mapsym)))))

  (with-current-buffer
      (new-buffer-from-string
       (concat (symbol-name mapsym) "\n\n" (show-map-as-string mapsym))
       (concat "∙" (symbol-name mapsym) "∙"))
    (view-mode 1))
  (fz-map-fn mapsym))

(provide 'pen-show-map)