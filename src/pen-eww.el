(defun eww-next-image ()
  (interactive)
  (goto-char (next-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (next-single-char-property-change (point) 'image-url))))

(defun eww-previous-image ()
  (interactive)
  (goto-char (previous-single-char-property-change (point) 'image-url))
  (if (not (get-text-property (point) 'image-url))
      (goto-char (previous-single-char-property-change (point) 'image-url))))

(define-key eww-mode-map (kbd "]") 'eww-next-image)
(define-key eww-mode-map (kbd "[") 'eww-previous-image)

(provide 'pen-eww)