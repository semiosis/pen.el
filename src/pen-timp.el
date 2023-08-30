(require 'signal)
(require 'timp-packet)
(require 'timp-server)

;; TODO In the future, consider managing pen workers with timp.
;; But not yet.

(defun pen-worker-get-port ()
  ;; Calculate from the daemon name
  9700)

(defun pen-timp-start-listener ()
  ;; (timp-server-init)
  (make-network-process :name timp-server-stream
                        :server t
                        :host 'local
                        :service t
                        :family 'ipv4
                        :filter 'timp-server-receive-data
                        :nowait t)
  (accept-process-output nil 0.1)
  (timp-server-send-port-data (pen-worker-get-port))
  (advice-add 'message :around 'timp-server-message)
  (while t (sleep-for 0.5)))

(provide 'pen-timp)