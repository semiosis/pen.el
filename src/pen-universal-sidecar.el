(require 'universal-sidecar)
(require 'universal-sidecar-roam)
(require 'universal-sidecar-elfeed-score)
(require 'universal-sidecar-elfeed-related)

(add-to-list 'universal-sidecar-sections
             '(universal-sidecar-roam-section org-roam-backlinks-section))

(provide 'pen-universal-sidecar)
