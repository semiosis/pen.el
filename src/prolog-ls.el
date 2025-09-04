(lsp-register-client
  (make-lsp-client
   :new-connection
   (lsp-stdio-connection (list "swipl"
                               "-g" "use_module(library(lsp_server))."
                               "-g" "lsp_server:main"
                               "-t" "halt"
                               "--" "stdio"))
   :major-modes '(prolog-mode)
   :priority 1
   :multi-root t
   :server-id 'prolog-ls))

(provide 'prolog-ls)
