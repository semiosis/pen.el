;; This is for prompt file creation

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

;; https://github.com/socketteer/loom/blob/main/model.py#L40

(defset default-generation-settings
  '(("num-continuations" . 4)
    ("temperature" . 0.9)
    ("top-p" . 1)
    ("response-length" . 100)
    ("prompt-length" . 6000)
    ("janus" . false)
    ("adaptive" . false)
    ("model" . "davinci")
    ("memory" . "")))

(defset default-visualization-settings
        '(
    ("textwidth" . 450)
    ("leafdist" . 200)
    ("leveldistance" . 150)
    ("textsize" . 10)
    ("horizontal" . true)
    ("displaytext" . true)
    ("showbuttons" . true)
))

(provide 'my-openai)