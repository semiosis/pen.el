(require 'quelpa)

(package-install 'quelpa-use-package)
(require 'quelpa-use-package)

;; Deprecated
;; (use-package matrix-client
;;   :quelpa (matrix-client :fetcher github :repo "alphapapa/matrix-client.el"
;;                          :files (:defaults "logo.png" "matrix-client-standalone.el.sh")))

;; Install Ement.
(use-package ement
  :quelpa (ement :fetcher github :repo "alphapapa/ement.el"))

(provide 'pen-quelpa)
