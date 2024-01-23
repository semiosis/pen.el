(require 'universal-sidecar)
(require 'universal-sidecar-roam)
(require 'universal-sidecar-elfeed-score)
(require 'universal-sidecar-elfeed-related)

(add-to-list 'universal-sidecar-sections 'buffer-git-status)
;; However, if we want the opposite behavior (don't show renames),
;; we'd configure it as shown below.
;; (add-to-list 'universal-sidecar-sections '(buffer-git-status :show-renames t))

(add-to-list 'universal-sidecar-sections
             '(universal-sidecar-roam-section org-roam-backlinks-section))

(provide 'pen-universal-sidecar)
