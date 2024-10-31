#!/usr/bin/env bb

;; sister script
;; e:$EMACSD/pen.el/scripts/clojure/utils/transform-lines.clj

(ns utils.transform-lines)

(require '[clojure.string :as str]
         '[clojure.java.io :as io])

(defn transform-line [line]
  (let [modified-line (str/replace line #"(\w+)\(\"(\d+)\", \"(.+)\"\),"
                                   "| $1 | $2 | $3 |")]
    modified-line))

;; (let [input-file (first *command-line-args*)
;;       ;; output-file (second *command-line-args*)
;;       ]
;;   (with-open [reader (io/reader input-file)
;;               ;; writer (io/writer output-file)
;;               ]
;;     (doseq [line (line-seq reader)]
;;       (when (not-empty line)
;;         (let [transformed-line (transform-line line)]
;;           (println transformed-line)
;;           ;; (.write writer (str transformed-line "\n"))
;;           )))))

(doseq [line (line-seq (clojure.java.io/reader *in*))]
  ;; (println (clojure.string/upper-case line))
  (println (transform-line line)))
