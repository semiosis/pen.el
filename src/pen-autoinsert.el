(require 'autoinsert)

(auto-insert-mode t)

;; ** TODO Fix this - I need to be able to use C-M-j in completing read, but I use that chord in tmux

(define-key minibuffer-local-map (kbd "<f12>") 'abort-recursive-edit)

(comment
 (tv (completing-read "Keyword, C-h: " '(a b) nil t))
 (tv (ivy-completing-read "Keyword, C-h: " '(a b) nil t)))

;; See:
;; e:$EMACSD/pen.el/src/pen-ivy.el

(provide 'pen-autoinsert)
