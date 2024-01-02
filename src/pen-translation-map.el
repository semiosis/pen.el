(define-key key-translation-map (kbd "<insertchar>") (kbd "C-M-i"))
(define-key key-translation-map (kbd "C-M-i") nil)

;; swap M-` and M-~
;; So I can execute commands using M-` and bring up the menu bar ith M-~
(define-key key-translation-map (kbd "<ESC> `") (kbd "<ESC> ~"))
(define-key key-translation-map (kbd "<ESC> ~") (kbd "<ESC> `"))

;; Make it so C-M-x works like C-x
;; To make easier:
;; C-x left
;; C-x right
(define-key key-translation-map (kbd "C-M-x") (kbd "C-x"))

(define-key key-translation-map (kbd "C-M-p") (kbd "<prior>"))
(define-key key-translation-map (kbd "C-M-n") (kbd "<next>"))
(define-key key-translation-map (kbd "C-8") (kbd "DEL"))

(define-key key-translation-map (kbd "<f49>") (kbd "<M-f1>"))
(define-key key-translation-map (kbd "<f50>") (kbd "<M-f2>"))
(define-key key-translation-map (kbd "<f51>") (kbd "<M-f3>"))
(define-key key-translation-map (kbd "<f52>") (kbd "<M-f4>"))

;; Make GUI emacs more like TUI emacs
(define-key key-translation-map (kbd "C-M-SPC") (kbd "C-M-@"))
(define-key key-translation-map (kbd "<insertchar>") (kbd "C-M-i")) ;M-TAB

;; Do this so that the bindings work everywhere, including helm etc.
(define-key key-translation-map (kbd "C-M-k") (kbd "<up>"))
(define-key key-translation-map (kbd "C-M-j") (kbd "<down>"))
(define-key key-translation-map (kbd "C-M-h") (kbd "<left>"))
(define-key key-translation-map (kbd "C-M-l") (kbd "<right>"))

(define-key global-map (kbd "<C-M-up>") (df up5 (ekm (s-repeat 5 "<up> "))))
(define-key global-map (kbd "<C-M-down>") (df down5 (ekm (s-repeat 5 "<down>"))))
(define-key global-map (kbd "<C-M-left>") (df left5 (ekm (s-repeat 5 "<left>"))))
(define-key global-map (kbd "<C-M-right>") (df right5 (ekm (s-repeat 5 "<right>"))))

(define-key key-translation-map (kbd "C-M-]") (kbd "<help>"))

;; This isn't used anywhere yet
(define-minor-mode pen-disable-keys-mode
  "Disables all keys."
  :lighter " dk"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-g") (λ ()
                                          (interactive)
                                          (pen-disable-keys-mode -1)))
            (define-key map [t] 'ignore)
            map))

;; Add Hyper and Super
(defun add-event-modifier (string e)
  (let ((symbol (if (symbolp e) e (car e))))
    (setq symbol (intern (concat string
                                 (symbol-name symbol))))
    (if (symbolp e)
        symbol
      (cons symbol (cdr e)))))

(defun superify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 23) e)
              (if (memq 'super (event-modifiers e))
                  e
                (add-event-modifier "s-" e))))))

(defun hyperify (prompt)
  (let ((e (read-event)))
    (vector (if (numberp e)
                (logior (lsh 1 24) e)
              (if (memq 'hyper (event-modifiers e))
                  e
                (add-event-modifier "H-" e))))))

(define-key global-map (kbd "C-M-6") nil)             ;For GUI
(define-key function-key-map (kbd "C-M-6") 'superify) ;For GUI
(define-key function-key-map (kbd "C-M-^") 'superify)
(define-key function-key-map (kbd "C-^") 'superify)
(define-key global-map (kbd "C-M-\\") nil) ;Ensure that this bindings isnt taken
(define-key function-key-map (kbd "C-M-\\") 'hyperify)

(provide 'pen-translation-map)
