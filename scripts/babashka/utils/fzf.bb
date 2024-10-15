#!/usr/bin/env bb

(ns utils.fzf)

(require '[babashka.process :as p])

(defn fzf [s]
  (let [proc (p/process ["fzf" "-m"]
                        {:in s :err :inherit
                         :out :string})]
    (:out @proc)))

(print (fzf (slurp *in*)))
