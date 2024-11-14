#!/usr/bin/env bbb

(ns utils.json-demo
  (:require [cheshire.core :refer :all]
            [babashka.json :as json]))

;; https://github.com/dakrone/cheshire

(defn generate-examples
  ""
  []

  ;; generate some json
  (generate-string {:foo "bar" :baz 5})

  ;; write some json to a stream
  (generate-stream {:foo "bar" :baz 5} (clojure.java.io/writer "/tmp/foo"))

  ;; generate some SMILE
  ;; (generate-smile {:foo "bar" :baz 5})

  ;; generate some JSON with Dates
  ;; the Date will be encoded as a string using
  ;; the default date format: yyyy-MM-dd'T'HH:mm:ss'Z'
  (generate-string {:foo "bar" :baz (java.util.Date. 0)})

  ;; generate some JSON with Dates with custom Date encoding
  (generate-string {:baz (java.util.Date. 0)} {:date-format "yyyy-MM-dd"})

  ;; generate some JSON with pretty formatting
  (generate-string {:foo "bar" :baz {:eggplant [1 2 3]}} {:pretty true})
  ;; {
  ;;   "foo" : "bar",
  ;;   "baz" : {
  ;;     "eggplant" : [ 1, 2, 3 ]
  ;;   }
  ;; }

  ;; generate JSON escaping UTF-8
  (generate-string {:foo "It costs £100"} {:escape-non-ascii true})
  ;; => "{\"foo\":\"It costs \\u00A3100\"}"

  ;; generate JSON and munge keys with a custom function
  (generate-string {:foo "bar"} {:key-fn (fn [k] (.toUpperCase (name k)))})
  ;; => "{\"FOO\":\"bar\"}"

  ;; generate JSON without escaping the characters (by writing it to a file)
  (spit "foo.json" (generate-string {:foo "bar"} {:pretty true})))

(defn decode-examples
  ""
  []

  ;; parse some json
  (parse-string "{\"foo\":\"bar\"}")
  ;; => {"foo" "bar"}

  ;; parse some json and get keywords back
  (parse-string "{\"foo\":\"bar\"}" true)
  ;; => {:foo "bar"}

  ;; parse some json and munge keywords with a custom function
  (parse-string "{\"foo\":\"bar\"}" (fn [k] (keyword (.toUpperCase k))))
  ;; => {:FOO "bar"}

  ;; top-level strings are valid JSON too
  (parse-string "\"foo\"")
  ;; => "foo"

  ;; parse some SMILE (keywords option also supported)
  ;; (parse-smile <your-byte-array>)

  ;; parse a stream (keywords option also supported)
  (parse-stream (clojure.java.io/reader "/tmp/foo"))

  ;; parse a stream lazily (keywords option also supported)
  (parsed-seq (clojure.java.io/reader "/tmp/foo"))

  ;; parse a SMILE stream lazily (keywords option also supported)
  ;; (parsed-smile-seq (clojure.java.io/reader "/tmp/foo"))
  )
