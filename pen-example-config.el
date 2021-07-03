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

;; These bindings will allow you to use Space Cadet keyboard modifiers
;; https://mullikine.github.io/posts/add-super-and-hyper-to-terminal-emacs/
;; C-M-6 = Super (s-)
;; C-M-\ = Hyper (H-)
;; Pen.el will make use of H-
(define-key global-map (kbd "C-M-6") nil)             ;For GUI
(define-key function-key-map (kbd "C-M-6") 'superify) ;For GUI
(define-key function-key-map (kbd "C-M-^") 'superify)
(define-key function-key-map (kbd "C-^") 'superify)
(define-key global-map (kbd "C-M-\\") nil) ;Ensure that this bindings isnt taken
(define-key function-key-map (kbd "C-M-\\") 'hyperify)

;; Ensure that you have yamlmod

;; https://github.com/perfectayush/emacs-yamlmod
(if module-file-suffix
    (progn
      (module-load "/home/shane/source/git/config/emacs/manual-packages/emacs-yamlmod/target/release/libyamlmod.so")
      (add-to-list 'load-path "/home/shane/source/git/config/emacs/manual-packages/emacs-yamlmod")
      (require 'yamlmod)
      (require 'yamlmod-wrapper)))

(require 'pen)
(pen 1)

(defalias 'camille-complete 'pen-run-prompt-function)

;; Camille-complete (because I press SPC to replace
(require 'selected)
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)

(define-key pen-map (kbd "H-TAB r") 'pen-run-prompt-function)
(define-key pen-map (kbd "M-1") #'company-pen-filetype)
(define-key pen-map (kbd "H-P") 'pen-complete-long)
(define-key pen-map (kbd "H-TAB g") 'pen-generate-prompt-functions)
(define-key pen-map (kbd "H-s") 'fz-pen-counsel)
(define-key pen-map (kbd "H-TAB s") 'pen-filter-with-prompt-function)

(require 'org-brain)
(require 'pen-brain)
(define-key org-brain-visualize-mode-map (kbd "C-c a") 'org-brain-asktutor)
(define-key org-brain-visualize-mode-map (kbd "C-c t") 'org-brain-show-topic)
(define-key org-brain-visualize-mode-map (kbd "C-c d") 'org-brain-describe-topic)

(setq pen-prompt-directory "/home/shane/var/smulliga/source/git/semiosis/prompts/prompts")
(setq pen-nlsh-histdir "/home/shane/notes/programs/comint/history/")