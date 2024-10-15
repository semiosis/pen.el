#!/usr/bin/env bb

(ns utils.random_doc
  (:require [babashka.process :as p]))

(require '[clojure.repl])

(defmacro random-doc []
  (let [sym (-> (ns-publics 'clojure.core) keys rand-nth)]
    (if (:doc (meta (resolve sym)))
      `(clojure.repl/doc ~sym)
      `(random-doc))))

(defn v [s]
  (let [proc (p/process ["sps" "v"]
                        {:in s :err :inherit
                         ;; :out :string
                         })]
    (:out @proc)))

(v (random-doc))
