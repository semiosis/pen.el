;; pen-engine allows you to configure the engines you want
;; For example, you may only want to use free(libre) engines, or private(local) engines, or powerful(openai) engines.

;; It should also provide redundancy
;; Detect what engines are available and select one

(require 'pen-configure)

;; TODO Make it so
;; - If a prompt requests more tokens than the engine can provide, find an appropriate engine



;; Forcing engines is not generally recommended
;; I should really make a tree of engines which can act as fall-backs

(defcustom pen-force-engine ""
  "Force using this engine"
  :type 'string
  :group 'pen
  :options (ht-keys pen-engines)
  :set (lambda (_sym value)
         (set _sym value))
  :get (lambda (_sym)
         (eval (sor _sym nil)))
  :initialize #'custom-initialize-default)

(provide 'pen-engine)