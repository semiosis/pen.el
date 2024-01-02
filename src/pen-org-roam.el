(require 'org-roam)
(require 'org-roam-ql)
(require 'org-roam-ql-ql)
(require 'org-roam-ui)

(setq org-roam-v2-ack t)

(use-package org-roam
  :ensure t
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (umn "$PEN/roam"))
  (org-roam-completion-everywhere t)
  ;; "C-c DEL C-l
  ;; is the same as:
  ;; "C-c C-8 C-l
  :bind (("C-c DEL C-l" . org-roam-buffer-toggle)
         ("C-c DEL C-f" . org-roam-node-find)
         ("C-c DEL C-i" . org-roam-node-insert)
         :map org-mode-map
         (("C-c DEL C-i" . org-roam-node-insert)
          ("C-c DEL C-o" . org-id-get-create)
          ("C-c DEL C-t" . org-roam-tag-add)
          ("C-c DEL C-a" . org-roam-alias-add)
          ("C-c DEL C-l" . org-roam-buffer-toggle)
          ;; ("C-M-i"    . completion-at-point)
          ))
  :config
  (org-roam-setup))

(provide 'pen-org-roam)
