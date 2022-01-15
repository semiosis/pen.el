;; This is for creating a read-only area at the top of human input buffers
;; - used to place the prompt
;; - used to tell the user what they are doing

(defface pen-read-only
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline t))
  "Read only face."
  :group 'pen-faces)

(defun pen-eipe-set-prompt-ro (end)
  ;; (point-min) is one char further than I need
  (put-text-property 0 end 'read-only t)
  (put-text-property 0 end 'face 'pen-read-only))

(provide 'pen-eipe)