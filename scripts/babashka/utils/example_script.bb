(ns utils.example-script
  ;; (:require [utils.common :refer :all])
  (:require [utils.common :as uc]))

;; https://8thlight.com/insights/clojure-libs-and-namespaces-require-use-import-and-ns
;; (require '[utils.common :as uc] :verbose)

;; [[sps:ewwlinks +/"was the file invoked from the command line" "https://book.babashka.org/"]]
(defn invoked-as-script-p
  "Check if the current file was the file invoked from the command line"
  []
  (= *file* (System/getProperty "babashka.file")))
