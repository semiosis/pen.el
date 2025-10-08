#!/usr/bin/env bb

;; sister script
;; e:$EMACSD/pen.el/scripts/clojure/utils/transform-lines.clj

;; https://stackoverflow.com/questions/17226863/merge-multiple-stdout-stderr-into-one-stdout

(ns utils.run-twice-and-mix-stdout-and-stderr)

(require '[clojure.string :as s]
         '[clojure.java.io :as io]
         '[utils.myshell :as myshell])

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

(let [clicmd (myshell/cmd-posix-1 *command-line-args*)
      ordered (myshell/snc (myshell/cmd-posix "unbuffer" "bash" "-c" clicmd))
      labelled (myshell/snc
                (str
                 ;; The myshell/cmd function needs improvement:
                 ;;   run-twice-and-mix-stdout-and-stderr bash -c ' cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | head -n 2000 | rosie-bibleverseref-grep "( { bibleverseref.john_name \" \" bibleverseref.chapter_verses } / { bibleverseref.john_name \" \" bibleverseref.chapter_set } )" -a -o sexp' | v
                 ;; Use nsfa for the time being:
                 ;;   batch run-twice-and-mix-stdout-and-stderr "$(nsfa bash -c ' cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | rosie-bibleverseref-grep "( { bibleverseref.john_name \" \" bibleverseref.chapter_verses } / { bibleverseref.john_name \" \" bibleverseref.chapter_set } )" -a -o sexp')"
                 (myshell/cmd
                  "unbuffer"
                  "bash" "-c"
                  (str clicmd " 2> >(sed \"s/^/ERR:/\")"))
                 "| awk \"!/^ERR:/ {gsub(/^/,\\\"OUT:\\\")}1\""))
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

      ;; It's getting through a lot but still breaks for some reason.
      ;; Sometimes it makes it all the way but usually it does not.
      ;; batch run-twice-and-mix-stdout-and-stderr.bb "$(nsfa bash -c ' cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | rosie-bibleverseref-grep "( { bibleverseref.john_name \" \" bibleverseref.chapter_verses } / { bibleverseref.john_name \" \" bibleverseref.chapter_set } )" -a -o sexp')" | v
      ;; The bash script can't get through the theology document in one go - it's too big.
      ;; The issue with this babashka script might not be the babashka script at all.
      ;; Sometimes the TTY/OUT/ERR capture files might be at fault.
      ;; Success e:/root/dump/tmp/scratchVY06S8.txt

      ;; TODO Do an experiment:
      ;; When it fails check ordlines, outlines and errlines and see if rosie is at fault

      ;; Sending input in linewise makes this even more reliable, because rosie gets the input one line at a time. But it slows things down
      ;; run-twice-and-mix-stdout-and-stderr.bb "$(nsfa bash -c 'cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | catnap 0 | rosie-bibleverseref-grep "( { bibleverseref.john_name \" \" bibleverseref.chapter_verses } / { bibleverseref.john_name \" \" bibleverseref.chapter_set } )" -a -o sexp')" | v
      (reverse
       (loop [ret_mixlines '()
              rem_ordlines ordlines
              rem_outlines outlines
              rem_errlines errlines]

         ;; (println (count rem_ordlines))
         ;; (println (first rem_ordlines))
         (cond
           (== 0 (count rem_ordlines)) ret_mixlines
           (= (first rem_ordlines) (first rem_outlines)) (recur (conj ret_mixlines (str "OUT:" (first rem_outlines)))
                                                                (rest rem_ordlines) (rest rem_outlines) rem_errlines)
           (= (first rem_ordlines) (first rem_errlines)) (recur (conj ret_mixlines (str "ERR:" (first rem_errlines)))
                                                                (rest rem_ordlines) rem_outlines (rest rem_errlines))
           :else
           (conj ret_mixlines (str "UNK:" (first rem_ordlines))
                 (str "OUT:" (first rem_outlines))
                 (str "ERR:" (first rem_errlines)))
           ;; (conj '() (str "UNK:" (first rem_ordlines))
           ;;       (str "OUT:" (first rem_outlines))
           ;;       (str "ERR:" (first rem_errlines)))
           )))]
  ;; (print (myshell/snc clicmd))
  ;; (print (myshell/snc (s/join " " outlines)))
  ;; (print (s/join "\n" ordlines))

  ;; I really need to think functionally about solving this problem


  ;; (print "ORDLINES")
  ;; (print (s/join "\n" ordlines))
  ;; (print "ERRLINES")
  ;; (print (s/join "\n" errlines))
  ;; (print "OUTLINES")
  ;; (print (s/join "\n" outlines))
  (print (s/join "\n" mixlines))
  ;; (print labelled)
  ;; (print test)
  ;; (print runcmd)
  )

;; (comment
;;   (doseq [line (line-seq (clojure.java.io/reader *in*))]
;;     ;; (println (s/upper-case line))
;;     (println (transform-line line))))
