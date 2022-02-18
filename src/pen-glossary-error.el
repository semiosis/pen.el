(defvar glossary-error-files nil)

(defset glossary-error-predicate-tuples
  (pen-mu `(
        ((ire-in-buffer-or-path-p "ghci")
         "$HOME/glossaries/haskell-errors.txt"))))

(defsetface glossary-error-button-face
  '((t
     :foreground "#880044"
     ;; :foreground nil
     ;; :background "#000022"
     :weight bold
     :underline t))
  "Face for glossary error buttons.")
(define-button-type 'glossary-error-button 'follow-link t 'help-echo "Click to go to error" 'face 'glossary-error-button-face)

(defun glossary-error-list-relevant-glossaries ()
  (-distinct (-flatten (cl-loop for tup in glossary-error-predicate-tuples collect (if (eval (car tup)) (cdr tup))))))

(defun append-glossary-error-files-locally (fps)
  (if (local-variable-p 'glossary-error-files)
      (defset-local glossary-error-files (-union glossary-error-files fps))
    (defset-local glossary-error-files fps)))

(defun add-error-glossaries-to-buffer (fps &optional no-draw)
  (if fps
      (save-excursion
        (progn
          (append-glossary-error-files-locally fps)
          (if (not no-draw)
              (draw-glossary-buttons-and-maybe-recalculate nil nil))))))

(defun glossary-error-add-relevant-glossaries (&optional no-draw)
  (interactive)
  (add-error-glossaries-to-buffer (glossary-error-list-relevant-glossaries) no-draw))

(defun recalculate-glossary-error-3tuples ()
  (interactive)
  (defset-local glossary-error-term-3tuples (-distinct (flatten-once (cl-loop for fp in glossary-error-files collect (glossary-list-tuples fp))))))

(provide 'pen-glossary-error)