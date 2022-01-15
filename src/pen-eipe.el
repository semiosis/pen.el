;; This is for creating a read-only area at the top of human input buffers
;; - used to place the prompt
;; - used to tell the user what they are doing

;; purple is a good font for a prompt
;; human(red) / ai(blue)
(defface pen-read-only
  '((t :foreground "#8b26d2"
       :background "#2e2e2e"
       :weight normal
       :slant italic
       :underline t))
  "Read only face."
  :group 'pen-faces)

(defun pen-eipe-set-prompt-ro (end)
  ;; Frustratingly, I can't seem to make the start of the buffer readonly
  ;; Maybe I can configure self-insert-command in the future.
  (ignore-errors
    (put-text-property (point-min) end 'face 'pen-read-only)
    (put-text-property (point-min) end 'read-only t)
    (put-text-property (point-min) end 'pen-eipe-prompt t)
    (try (goto-char (+ 1 end))
         (goto-char end)
         nil)))

(defun pen-find-file-read-only-context ()
  (if (f-exists-p (concat "~/.pen/eipe_" (pen-daemon-name) "_prompt"))))

(defset pen-eipe-hook '())

(add-hook 'pen-eipe-hook 'pen-find-file-read-only-context)

(defun run-eipe-hooks ()
  (interactive)
  (run-hooks 'pen-eipe-hook))

(add-hook 'find-file-hooks 'run-eipe-hooks t)

(provide 'pen-eipe)