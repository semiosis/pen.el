(defcustom pen-proxy ""
  "Example: localhost:9837"
  :type 'string
  :group 'pen
  :options (list "localhost")
  :set (λ (_sym value)
         (if (string-equal "localhost" value)
             (setq value (concat "localhost:" (str (pen-get-khala-port)))))
         (set _sym value))
  :get (λ (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(defun pen-proxy-set-localhost ()
  "This is for debugging the proxy"
  (interactive)
  (setq pen-proxy (concat "localhost:" (str (pen-get-khala-port)))))

;; (defset pen-proxy nil)

;; Proxy is a host and a port
;; (defset pen-proxy "localhost:9707")

(provide 'pen-proxy)