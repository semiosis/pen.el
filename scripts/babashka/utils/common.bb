(ns utils.common)

;; [[sps:ewwlinks +/"was the file invoked from the command line" "https://book.babashka.org/"]]
(defn invoked-as-script-p
  "Check if the current file was the file invoked from the command line"
  []
  (= *file* (System/getProperty "babashka.file")))

