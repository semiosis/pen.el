(comment
 (text-property-search-forward 'file-path) ;; Which returns something like this ;; (comment ;;  ;; The type is not a string, but a 'prop-match' ;;   (ly-raw newline)prop-match 14182 14185
 ;;                #("///lib" 3 6
 ;;                  (keymap
 ;;                   (keymap
 ;;                    (mouse-1 . pen-find-file)
 ;;                    (13 . pen-find-file))
 ;;                   font-lock-face eshell-ls-directory mouse-face highlight help-echo "RET: find file" file-path "///lib"))))
 )

(comment
 (let ((tups))
   (goto-char (point-min))
   (while (setq match (text-property-search-forward 'file-path))
     (push (cons
            (str (buffer-substring
                  (prop-match-beginning match)
                  (prop-match-end match)))
            (prop-match-beginning match))
           tups))
   (reverse tups)))

(comment
 ;; Should return a list like this
 (("selectrum-mode(m)" . 1)
  ("pen-trace-mode(m)" . 19)
  ("pen-toggle-draw-glossary-buttons-timer(c)" . 37)))

(comment
 (pen-textprop-collect 'file-path))

;; j:ace-link-goto-eshell-file-path
(defun pen-textprop-collect (prop)
  "Collect the positions of text with matching properties in the current buffer."
  (let ((tups))
    (save-excursion
      (goto-char (point-min))
      (while (setq match (text-property-search-forward prop))
        (push (cons
               (str (buffer-substring
                     (prop-match-beginning match)
                     (prop-match-end match)))
               (prop-match-beginning match))
              tups)))
    (reverse tups)))

(defun pen-textprops-in-region-or-buffer ()
  (if (region-active-p)
      (format "%S" (buffer-substring (region-beginning) (region-end)))
    (format "%S" (buffer-string))))

;; (pen-add-textprops "dfkslj" 'file-path "/")
(defun pen-add-textprops (s &rest props)
  (with-temp-buffer
    (insert s)
    (add-text-properties (point-min) (point-max) props)
    (buffer-string)))

(defun pen-etv-textprops ()
  (interactive)
  (new-buffer-from-string (pen-textprops-in-region-or-buffer)))

(define-key pen-map (kbd "M-l M-p M-t") 'pen-etv-textprops)

(provide 'pen-textprops)
