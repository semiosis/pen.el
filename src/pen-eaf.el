;; (add-to-list 'load-path "/root/repos/emacs-eaf/emacs-application-framework")
;; (require 'eaf)

(use-package eaf
  :load-path "/root/repos/emacs-eaf/emacs-application-framework"
  :custom
  ;; See https://github.com/emacs-eaf/emacs-application-framework/wiki/Customization
  (eaf-browser-continue-where-left-off t)
  (eaf-browser-enable-adblocker t)
  (browse-url-browser-function 'eaf-open-browser)
  :config
  (defalias 'browse-web #'eaf-open-browser)
  (eaf-bind-key scroll_up "C-n" eaf-pdf-viewer-keybinding)
  (eaf-bind-key scroll_down "C-p" eaf-pdf-viewer-keybinding)
  (eaf-bind-key take_photo "p" eaf-camera-keybinding)
  (eaf-bind-key nil "M-q" eaf-browser-keybinding))

(require 'eaf-browser)
(require 'eaf-pdf-viewer)

(provide 'pen-eaf)
