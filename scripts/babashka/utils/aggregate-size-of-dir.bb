#!/usr/bin/env bb

(ns utils.aggregate-size-of-dir)

;; Even though bb has default imports such as io,
;; I want the LSP serve to automatically do the loading

(require '[clojure.java.io :as io])

(as-> (io/file (or (first *command-line-args*) ".")) $
  (file-seq $)
  (map #(.length %) $)
  (reduce + $)
  (/ $ (* 1024 1024))
  (println (str (int $) "M")))
