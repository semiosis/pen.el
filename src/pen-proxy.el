(defcustom pen-proxy ""
  "Example: localhost:9707"
  :type 'string
  :group 'pen
  ;; :options (ht-keys pen-engines)
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(defset pen-proxy nil)

;; Proxy is a host and a port
(defset pen-proxy "localhost:9707")

(provide 'pen-proxy)