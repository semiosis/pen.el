(require 'undo-fu)
(require 'pen-hydra)

;; DONE Make a hydra that stays up - so I can tap to keep undoing

(defun undo-fu-undo-all ()
  (interactive)
  (while (undo-fu-only-undo)
    nil))

(global-set-key
 (kbd "H-z")
 (defhydra handleundo (:pre (prehydra) :post (posthydra) :columns 4) ;; "handle undo"
   "undo"
   ("u" undo-fu-only-undo "undo")
   ("r" undo-fu-only-redo "redo")
   ("U" undo-fu-undo-all "undo all")
   ("R" undo-fu-only-redo-all "redo all")
   ("c" undo-fu-clear-all "clear")
   ("q" nil "quit" :color blue)))

(provide 'pen-undo-fu)
