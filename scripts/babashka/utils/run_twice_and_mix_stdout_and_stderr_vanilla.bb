#!/usr/bin/env bb

(ns utils.run-twice-and-mix-stdout-and-stderr)

;; https://stackoverflow.com/questions/17226863/merge-multiple-stdout-stderr-into-one-stdout

(require '[clojure.string :as s]
         '[clojure.java.io :as io])

(use '[clojure.java.shell :only [sh]])

(defn snc [s]
  (:out
   (sh "sh" "-c" s :in (str s))))

(let [clicmd (s/join " " *command-line-args*)
      ordered (snc
               (format "\"unbuffer\" \"bash\" \"-c\" \"%s\""
                       clicmd))
      labelled (snc
                (format
                 "\"unbuffer\" \"bash\" \"-c\" \"%s 2> >(sed \\\"s/^/ERR:/\\\")\"| awk \"!/^ERR:/ {gsub(/^/,\\\"OUT:\\\")}1\""
                 clicmd))
      ordlines (s/split-lines ordered)
      lablines (s/split-lines labelled)
      outlines (map
                (fn [s] (s/replace s #"^OUT:" ""))
                (filter
                 (fn [s] (= 0 (s/index-of s "OUT:")))
                 (s/split-lines
                  labelled)))
      errlines (map
                (fn [s] (s/replace s #"^ERR:" ""))
                (filter
                 (fn [s] (= 0 (s/index-of s "ERR:")))
                 (s/split-lines
                  labelled)))

      mixlines

      (reverse
       (loop [ret_mixlines '()
              rem_ordlines ordlines
              rem_outlines outlines
              rem_errlines errlines]
         (cond
           (== 0 (count rem_ordlines)) ret_mixlines
           (= (first rem_ordlines) (first rem_outlines)) (recur (conj ret_mixlines (str "OUT:" (first rem_outlines)))
                                                                (rest rem_ordlines) (rest rem_outlines) rem_errlines)
           (= (first rem_ordlines) (first rem_errlines)) (recur (conj ret_mixlines (str "ERR:" (first rem_errlines)))
                                                                (rest rem_ordlines) rem_outlines (rest rem_errlines))
           :else
           (conj ret_mixlines (str "UNK:" (first rem_ordlines))
                 (str "OUT:" (first rem_outlines))
                 (str "ERR:" (first rem_errlines))))))]
  (print (s/join "\n" mixlines)))
