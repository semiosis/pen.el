;; pen-engine allows you to configure the engines you want
;; For example, you may only want to use free(libre) engines, or private(local) engines, or powerful(openai) engines.

;; It should also provide redundancy
;; Detect what engines are available and select one

(require 'pen-configure)

;; TODO Make it so
;; - If a prompt requests more tokens than the engine can provide, find an appropriate engine

(provide 'pen-engine)