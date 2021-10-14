;; This is where buffer state is managed for Pen.el
;; It lets you specify Pen.el hyperparameters on a per-buffer basis

(require 'pen-transient)

(define-key pen-map (kbd "H-H") 'buffer-hyperparameters-transient)

(define-transient-command buffer-hyperparameters-transient ()
  "Transient for pulling images."
  :man-page "docker-image-pull"
  ["Arguments"
   ("-a" "All" "-a")]
  [:description docker-utils-generic-actions-heading
   ("F" "Pull selection" docker-utils-generic-action)
   ("T" "Pull specific tag (sps)" my-docker-pull-specific-tag)
   ("N" "Pull a new image" docker-image-pull-one)])

(provide 'pen-buffer-state)