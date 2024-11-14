#!/usr/bin/env -S clojure-shebang

(ns utils.json-demo
  (:require [babashka.json :as json]))

(defn json-test []
  (println "Testing provider" (json/get-provider))
  (= [1 2 3] (json/read-str "[1, 2, 3]"))
  (= {:a 1} (json/read-str "{\"a\": 1}"))
  (= {:a 1} (json/read-str "{\"a\": 1}" {:key-fn keyword}))
  (= {"a" 1} (json/read-str "{\"a\": 1}" {:key-fn str}))
  
  (= [1 2 3] (json/read-str (json/write-str [1 2 3])))
  (= {:a 1} (json/read-str (json/write-str {:a 1})))
  
  (let [rdr (json/->json-reader (java.io.StringReader. "{\"a\": 1}"))]
    (= {:a 1} (json/read rdr)))
  
  (let [rdr (json/->json-reader (java.io.StringReader. "{\"a\": 1}")
                                {:key-fn str})]
    (= {"a" 1} (json/read rdr {:key-fn str}))))

(defn provider-test []
  (let [prop (some-> (System/getProperty "babashka.json.provider") not-empty symbol)]
    (when prop
      (= prop (json/get-provider)))))

