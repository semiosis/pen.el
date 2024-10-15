(ns basic-cli-tool.core
  (:require
   [clojure.main]))

(comment
  (require '[basic-cli-tool.core :as c]))

(defn main
  []
  (clojure.main/repl)
  (println "Repl closed"))
