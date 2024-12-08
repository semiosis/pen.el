(require 'org-transclusion)

(comment
 (define-key global-map (kbd "<f12>") #'org-transclusion-add)
 (define-key global-map (kbd "C-n t") #'org-transclusion-mode))

(provide 'pen-org-transclusion)
