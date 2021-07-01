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
(define-key global-map (kbd "H-TAB r") 'pen-run-prompt-function)

;; Camille-complete (because I press SPC to replace
(define-key selected-keymap (kbd "SPC") 'pen-run-prompt-function)
(define-key selected-keymap (kbd "M-SPC") 'pen-run-prompt-function)