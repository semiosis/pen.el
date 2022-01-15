;; This is for creating a read-only area at the top of human input buffers
;; - used to place the prompt
;; - used to tell the user what they are doing

(defun pen-eipe-set-prompt-ro (end)
  (put-text-property (point-min) end 'read-only t))

(provide 'pen-eipe)