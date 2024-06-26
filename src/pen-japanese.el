;; Japanese-writing mode
(require 'org)

(define-derived-mode japanese-org-mode org-mode "japanese"
  "Major mode for writing in Japanese"
  (setq mode-name "japanese-org"))

(add-to-list 'magic-mode-alist '("^# japanese" . japanese-org-mode))

(provide 'pen-japanese)
