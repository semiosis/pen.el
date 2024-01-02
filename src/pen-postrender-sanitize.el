

;; Because this sanitizes post-rendered text,
;; I should only use buffer-manipulation functions
(defun sanitize-postrendered (beg end)
  (interactive "r")

  ;; (with-writable-buffer
  ;;  ;; (replace-regexp-in-region "[\x7f\u2028\u2029\ufe0f\u200a\u200c\ufe0f]+" "" (point-min) (point-max))
  ;;  (replace-regexp-in-region "[\x7f\u2028\u2029\ufe0f\u200a\u200c\ufe0f]+" "" beg end)
  ;;  ;; (with-writable-buffer
  ;;  ;;  (filter-selected-region-through-function 'notmuch-sanitize))
  ;;  (region-erase-trailing-whitespace beg end)
  ;;  (replace-regexp "^\\*$" "" nil beg end)
  ;;  (collapse-blank-lines beg end))

  (with-writable-buffer
   (progn-dontstop
    (replace-regexp-in-region "[\x7f\u2028\u2029\ufe0f\u200a\u200c\ufe0f]+" "" beg end)

    ;; region-erase-trailing-whitespace is failing
    ;; for an unknown reason inside eww
    (region-erase-trailing-whitespace beg end)
    (replace-regexp "^\\*$" "" nil beg end)
    (collapse-blank-lines beg end))))

(defalias 'notmuch-sanitize-postrendered 'sanitize-postrendered)
(defalias 'eww-sanitize-postrendered 'sanitize-postrendered)

(provide 'pen-postrender-sanitize)
