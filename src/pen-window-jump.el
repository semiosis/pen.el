(require 'window-jump)

;; <f1> bindings seem to be related to <help> bindings in emacs somehow
;; but two keys are very much different.

;; I have to find a way to stop <f1> and <help> being so bound.

;; <HELP>
;; [[info:emacs#Glossary][Emacs Info: emacs#Glossary]]
;; <HELP> is the Emacs name for ‘C-h’ or <F1>.  You can type <HELP> at
;; any time to ask what options you have, or to ask what a command
;; does.  *Note Help::.

;; (define-key global-map [help] 'help-command)
;; (define-key global-map [f1] 'help-command)

;; I had to unbind f1 from help, like this:
(define-key global-map [f1] nil)

(define-key global-map (kbd "<f1> k") 'window-jump-up)
(define-key global-map (kbd "<f1> j") 'window-jump-down)
(define-key global-map (kbd "<f1> h") 'window-jump-left)
(define-key global-map (kbd "<f1> l") 'window-jump-right)
(global-set-key (kbd "<f1> o") #'other-window)

(provide 'pen-window-jump)
