(require 'quelpa)
(require 'quelpa-use-package)

(use-package matrix-client
  :quelpa (matrix-client :fetcher github :repo "alphapapa/matrix-client.el"
                         :files (:defaults "logo.png" "matrix-client-standalone.el.sh")))

(provide 'pen-quelpa)