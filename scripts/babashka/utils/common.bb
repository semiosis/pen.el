(ns utils.common
  (:require [utils.misc :as ms]
            [clojure.string :as s]
            [clojure.java.io :as io]))

(comment
  (require ))

;; [[sps:ewwlinks +/"was the file invoked from the command line" "https://book.babashka.org/"]]
(defn invoked-as-script-p
  "Check if the current file was the file invoked from the command line"
  []
  (= *file* (System/getProperty "babashka.file")))

