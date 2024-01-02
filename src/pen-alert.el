(require 'alert)

;; This is a separate package but it will
;; notifiy my of many things, including slack
;; messages,
(use-package alert
  :commands (alert)
  :init
  (setq alert-default-style 'libnotify)
  (setq alert-libnotify-command (locate-binary "notify-send")))

;; (setq alert-default-style 'libnotify)

;; $EMACSD/pen.el/scripts/notify-send

(provide 'pen-alert)
