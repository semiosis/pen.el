(require 'signal)
(require 'timp-packet)
(require 'timp-server)

;; TODO In the future, consider managing pen daemons with timp.
;; But not yet.

(defun pen-timp-start-listener ()
  (timp-server-init))

(provide 'pen-timp)