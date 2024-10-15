#!/usr/bin/env bbb

(ns basic-cli-tool.core
  (:require
   [clojure.main]
   [is-tty]))

;; TODO Consider making a pen-bb-shebang command for running these scripts

(comment
  (require '[basic-cli-tool.core :as c])
  (require '[is-tty :as istty]))

(defn main
  []
  (if (and
       (is-tty/out-is-tty?)
       (is-tty/in-is-tty?)
       (is-tty/err-is-tty?))
    (clojure.main/repl))
  (println "Repl closed"))
