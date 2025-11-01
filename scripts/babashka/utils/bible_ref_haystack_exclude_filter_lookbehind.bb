#!/usr/bin/env bbb

;; sister script
;; e:$EMACSD/pen.el/scripts/clojure/utils/transform-lines.clj

;; Take output from this:
;;     cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | rosie-bibleverseref-grep "( { bibleverseref.john_name \" \" bibleverseref.chapter_verses } / { bibleverseref.john_name \" \" bibleverseref.chapter_set } )" -o sexp | get-haystacks-and-findstrs-from-rosie-grep-sexp-els | v
;; - load into tuples
;; - remove every tuple which has the exclusion string in the first element directly preceding the string that is in the 2nd elment

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


;; https://github.com/functional-koans/clojure-koans
;; e:$MYGIT/functional-koans/clojure-koans


;; Now collect all the exclusion patterns from the cli arglist

(defn matches-any-lookbehinds
  ""
  [s lookbehinds]

  (aliases/foreach [lb lookbehinds]
                   (when-let [executable a]
                     (if (re-find (re-pattern (str " of" findstr)) haystack)
                       (println haystack)
                       ;; (println (str "[" findstr "]=[" haystack "]"))
                       ;; (println haystack)
                       )
                     (println (myshell/tv (which executable))))))


;; Cider REPL doesn't hang because this uses a -main function

(defn -main [& args]
  ;; bbb handles the -main well now.
  ;; So does lispy E in cider
  (if args

    (doseq [tup (partition 2 (line-seq (clojure.java.io/reader *in*)))]
      ;; (println (clojure.string/upper-case line))
      ;; (println (transform-line line))

      (let [haystack (first tup)
            findstr (second tup)]

        (if (re-find (re-pattern (str " of" findstr)) haystack)
          (println haystack)
          ;; (println (str "[" findstr "]=[" haystack "]"))
          ;; (println haystack)
          )))

    (do
      (comment
        ;; This works, but I want to use standard clojure
        (aliases/foreach [a args]
                         (when-let [executable a]
                           (println (myshell/tv (which executable))))))
      (doseq [a args]
        (when-let [executable a]
          (println (myshell/tv (which executable))))))
    (when-let [executable (first *command-line-args*)]
      (println (which executable)))))
