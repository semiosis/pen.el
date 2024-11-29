#!/usr/bin/env bb

(ns utils.fzf
  (:require [utils.common :as uc]))

(require '[babashka.process :as p])

(defn fzf [s]
  (let [proc (p/process ["fzf" "-m"]
                        {:in s :err :inherit
                         :out :string})]
    (:out @proc)))

(defn sps-fzf [s]
  (let [proc (p/process ["sout" "sps" "fzf" "-m"]
                        {:in s :err :inherit
                         :out :string})]
    (:out @proc)))

(comment
  (print (fzf (slurp *in*)))
  (print (sps-fzf (slurp *in*))))

;; TODO Make it so it waits

(when (uc/invoked-as-script-p)
  (print (sps-fzf (slurp *in*))))
