(require 'openai-api)

;; This is for prompt file creation and more direct access to the openai-api

;; Model list taken from loom
;; https://github.com/socketteer/loom/blob/main/model.py

;; Use (pen-openai-list-engines)
(defset openai-models
  (list
   "ada"
   "babbage"
   "content-filter-alpha-c4"
   "content-filter-dev"
   "curie"
   "cursing-filter-v6"
   "davinci"
   "instruct-curie-beta"
   "instruct-davinci-beta"))

;; Defaults taken from loom
;; https://github.com/socketteer/loom/blob/main/model.py#L40

(defset default-generation-settings
  '(("num-continuations" . 4)
    ("temperature" . 0.9)
    ("top-p" . 1)
    ("response-length" . 100)
    ("prompt-length" . 6000)
    ("model" . "davinci")))

(defun pen-openai-list-engines ()
  (pen-str2list
   (pen-snc "pen-openai api engines.list | jq -r '.data[].id'")))
(memoize 'pen-openai-list-engines)


(provide 'pen-openai)