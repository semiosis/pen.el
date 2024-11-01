(ns openai-complete-clj.core
  (:require [libpython-clj2.require :refer [require-python]]
            [libpython-clj2.python :refer
               ;; The first 3 are the only ones I really need
             [py. py.. py.-

                ;; experimental
                ;; $a $c
                ;; from-import import-as

                ;; extras
                ;; as-python as-jvm
                ;; ->python ->jvm
                ;; get-attr call-attr call-attr-kw
                ;; get-item initialize!
                ;; run-simple-string
                ;; add-module module-dict
                ;; import-module
                ;; python-type
              ]:as py])
  (:gen-class))

;; (py/initialize! :python-executable
;;                 "/home/shane/local/bin/python3.6"
;;                 ;; "/opt/anaconda3/envs/my_env/bin/python3.7"
;;                 :library-path
;;                 ;; "/home/shane/local/lib/libpython3.6m.a"
;;                 "/snap/gnome-3-28-1804/145/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/libpython3.6.so"
;;                 ;; "/opt/anaconda3/envs/my_env/lib/libpython3.7m.dylib"
;;                 )

(require-python '[openai :as oai])
(require '[clojure.java.shell :as sh])
;; (py. oai create 1 )

(def oai-completion (oai/Completion))

;; ($a oai.Completion create {:prompt "Hello"})

;; due to the bug, i have to find another way to export the environment variable to lein.
;; it might not be a bug. it could be that writing to modules is not supported yet.
;; I should make a wrapper around lein.
;; The lein wrapper worked.
(comment
  (System/getenv "OPENAI_API_KEY")
  (let [key (:out (sh/sh "cat" "$PEN/openai_api_key"))]
    ;; For some reason api_key does not appear under here
    ;; (dir oai)

    ;; oai is not an object. it's a module
    ;; (py/set-attr! oai "api_key" key)

    ;; This doesn't set the key in the right scope
    ;; (run-simple-string (str "import openai; openai.api_key = \"" key "\""))

    ;; no such var - however this should work, i think in theory
    ;; It appears that oai/api_key doesnt exit. that may be a bug in libpython/clj.
    ;; other variables exist
    ;; (swap! oai/api_key identity key)
    ;; actually it wouldnt work because the following doesnt work
    ;; (swap! oai/api_base identity "dklsfjd")

    ;; (py/set-item! oai "api_key" key)
    ;; (py/set-attr! oai "api_key" key)

    ;; This doesn't work either
    ;; (def oai/api_base "dklsfjd")
    ))

;; This works. I don't know how it's different from py. yet
;; ($a oai-completion create :prompt "Once upon a time" :engine "davinci")
;; This works too
;; openai.Completion.create(engine="davinci-codex", prompt="Once upon a time", max_tokens=50)
;; (py. oai-completion create :prompt "Once upon a time" :engine "davinci" :max_tokens 50)

[score_multiplier 100.0
    api_token (System/getenv "PEN_KEY")
    pen_model (System/getenv "PEN_MODEL")
    pen_prompt (System/getenv "PEN_PROMPT")
    pen_suffix (System/getenv "PEN_SUFFIX")
    pen_payloads (System/getenv "PEN_PAYLOADS")
    pen_documents (System/getenv "PEN_DOCUMENTS")
    pen_mode (System/getenv "PEN_MODE")
    pen_temperature (System/getenv "PEN_TEMPERATURE")
    pen_stop_sequences (System/getenv "PEN_STOP_SEQUENCES")
    pen_stop_sequence (System/getenv "PEN_STOP_SEQUENCE")
    pen_logprobs (System/getenv "PEN_LOGPROBS")
    pen_end_pos (or (System/getenv "PEN_END_POS")
                    (count pen_prompt))
    collect_from_pos (or (System/getenv "PEN_COLLECT_FROM_POS")
                         pen_end_pos)
    pen_top_k (System/getenv "PEN_TOP_K")
    pen_top_p (System/getenv "PEN_TOP_P")
    pen_search_threshold (System/getenv "PEN_SEARCH_THRESHOLD")
    pen_query (System/getenv "PEN_QUERY")
    pen_gen_uuid (System/getenv "PEN_GEN_UUID")
    pen_gen_time (System/getenv "PEN_GEN_TIME")]

(defn -main
  "I don't do a whole lot ... yet."
  [& args]

  ;; (System/getenv "OPENAI_API_KEY")
  (let*
      [score_multiplier 100.0
       api_token (System/getenv "PEN_KEY")
       pen_model (System/getenv "PEN_MODEL")
       pen_prompt (System/getenv "PEN_PROMPT")
       pen_suffix (System/getenv "PEN_SUFFIX")
       pen_payloads (System/getenv "PEN_PAYLOADS")
       pen_documents (System/getenv "PEN_DOCUMENTS")
       pen_mode (System/getenv "PEN_MODE")
       pen_temperature (System/getenv "PEN_TEMPERATURE")
       pen_stop_sequences (System/getenv "PEN_STOP_SEQUENCES")
       pen_stop_sequence (System/getenv "PEN_STOP_SEQUENCE")
       pen_logprobs (System/getenv "PEN_LOGPROBS")
       pen_end_pos (or (System/getenv "PEN_END_POS")
                       (count pen_prompt))
       collect_from_pos (or (System/getenv "PEN_COLLECT_FROM_POS")
                            pen_end_pos)
       pen_top_k (System/getenv "PEN_TOP_K")
       pen_top_p (System/getenv "PEN_TOP_P")
       pen_search_threshold (System/getenv "PEN_SEARCH_THRESHOLD")
       pen_query (System/getenv "PEN_QUERY")
       pen_gen_uuid (System/getenv "PEN_GEN_UUID")
       pen_gen_time (System/getenv "PEN_GEN_TIME")]

      (if (> pen_top_p 1.0)
        pen_top_p)

      (println pen_prompt)

      ;; This makes it quit faster, but libpython-clj has a slow startup time
      (System/exit 0))

  ;; (comment
  ;;   (py. oai-completion create :prompt "Once upon a time" :engine "davinci" :max_tokens 50))
  ;; (println "Hello, World!")
  )
