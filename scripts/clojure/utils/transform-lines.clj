#!/usr/bin/env -S clojure-shebang
;; #!/usr/bin/env -S clojure-shebang -t

;; Deps are in the clojure-shebang script

(ns utils.transform-lines)

(require '[clojure.string :as s]
         '[clojure.java.io :as io])

(defn transform-line [line]
  (let [modified-line (s/replace line #"(\w+)\(\"(\d+)\", \"(.+)\"\),"
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
