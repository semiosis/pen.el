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

(defun showmap--read-symbol-minor-mode ()
  (let* ((local-minor-modes-with-map (-filter (lambda (minorm) (variable-p (str2sym (concat (str minorm) "-map")))) local-minor-modes))
         (minormodename (fz local-minor-modes-with-map nil nil "Local minor mode map")))
    (if (str minormodename)
        (str2sym (concat minormodename "-map")))))

(defmacro variable-name-re-p (re)
  "Predicate for a variable with name matching regex"
  `(lambda (object)
       (and (variable-p object)
            (not (not (string-match-p ,re (symbol-name object)))))))

(defun show-map-as-string (&optional mapsym)
  (interactive (list (showmap--read-symbol "map: " (variable-name-re-p "-map$"))))

  (if (not mapsym)
      (setq mapsym (current-major-mode-map)))

  (if (stringp mapsym)
      (setq mapsym (eval (intern (mapsym)))))

  ;; TODO Make it also show the title bar stuff, which is contained inside the map
  (let* ((mstring (concat "\\{" (symbol-name mapsym) "}"))
         (mstring_data (substitute-command-keys mstring)))

    (concat (if (sor mstring_data)
                (concat (substitute-command-keys mstring) "\n\n")
              "No keyboard bindings set for this map.\n\n")
            "Raw keymap data:\n"
            (pps (eval mapsym)))

    ;; Perhaps just concat the prettied variable data
    ))

(defun fz-map-fn (&optional mapsym)
  "fuzzy find maps and pretty print them in a new buffer"
  (interactive (list (showmap--read-symbol "map: " (variable-name-re-p "-\\(key\\)?map$"))))

  (if (not mapsym)
      (setq mapsym (current-major-mode-map)))

  (if (stringp mapsym)
      (setq mapsym (eval (intern (mapsym)))))

  (if (>= (prefix-numeric-value current-prefix-arg) 4)
      (show-map mapsym)
    (let ((prefix-numeric-value nil))
      ;; (run-mode-function mapsym)
      ;; (copy-mode-function mapsym)
      (help-for-mode-function mapsym)
      ;; (helpful-symbol mapsym)
      )))

(defun show-map (&optional mapsym)
  "fuzzy find maps and pretty print them in a new buffer"
  (interactive (list
                (let ((gparg (prefix-numeric-value current-prefix-arg))
                      (current-prefix-arg nil))
                  (cond ((>= gparg 16) nil)
                        ((>= gparg 4) (showmap--read-symbol-minor-mode))
                        (t (showmap--read-symbol "map: " (variable-name-re-p "-\\(key\\)?map$")))))))

  ;; TODO Make it also show the title bar stuff, which is contained inside the map
  (let ((current-prefix-arg nil))
    (if (not mapsym)
        (setq mapsym (current-major-mode-map)))

    (if (stringp mapsym)
        (setq mapsym (eval (intern (mapsym)))))

    (let ((bindings (concat (symbol-name mapsym) "\n\n" (show-map-as-string mapsym))))
      (if (or
           (major-mode-p 'crossword-mode)
           (>= (prefix-numeric-value current-global-prefix-arg) 4))

          (tpop "v" bindings)
        ;; (nw "v" nil bindings)

        (with-current-buffer
            (new-buffer-from-string
             bindings
             (concat "∙" (symbol-name mapsym) "∙"))
          (view-mode 1))))

    (fz-map-fn mapsym)))

(provide 'pen-show-map)
