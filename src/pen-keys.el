(defun pen-add-key-booste (key)
  (interactive (list (pen-read-service-key "booste")))
  (pen-add-key "booste" key))

(defun pen-add-key-alephalpha (key)
  (interactive (list (pen-read-service-key "alephalpha")))
  (pen-add-key "alephalpha" key))

(defun pen-add-key-openai (key)
  (interactive (list (pen-read-service-key "openai")))
  (pen-add-key "openai" key))

(defun pen-add-key-cohere (key)
  (interactive (list (pen-read-service-key "cohere")))
  (pen-add-key "cohere" key))

(defun pen-add-key-goose (key)
  (interactive (list (pen-read-service-key "goose")))
  (pen-add-key "goose" key))

(defun pen-add-key-ai21 (key)
  (interactive (list (pen-read-service-key "ai21")))
  (pen-add-key "ai21" key))

(defun pen-add-key-aix (key)
  (interactive (list (pen-read-service-key "aix")))
  (pen-add-key "aix" key))

(defun pen-add-key-hf (key)
  (interactive (list (pen-read-service-key "hf")))
  (pen-add-key "hf" key))

(provide 'pen-keys)