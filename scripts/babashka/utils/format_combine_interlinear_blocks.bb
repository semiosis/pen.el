#!/usr/bin/env bbb

;; sister script
;; e:$EMACSD/pen.el/scripts/clojure/utils/transform-lines.clj

;; https://stackoverflow.com/questions/17226863/merge-multiple-stdout-stderr-into-one-stdout

(ns utils.format-combine-interlinear-blocks)

(require '[clojure.string :as s]
         '[clojure.java.io :as io]
         '[utils.myshell :as myshell])

(defn biblehub-interlinear-join-blocks [a b]
  (myshell/snc "ved-move-biblehub-interlinear-block-up" (str a "\n\n" b)))

;; ocif curl "https://biblehub.com/interlinear/genesis/1-1.htm" | biblehub-interlinear-get-word-blocks-pipeline | sed '${/^$/d}' | ved-move-biblehub-interlinear-block-up | ved-move-biblehub-interlinear-block-up | ved-move-biblehub-interlinear-block-up | v
;; There's something wrong with myshell/sn because the output is different
(defn test-biblehub-interlinear-join-blocks-a
  []
  (myshell/tv (myshell/sn "ocif curl \"https://biblehub.com/interlinear/genesis/1-1.htm\" | biblehub-interlinear-get-word-blocks-pipeline | sed '${/^$/d}' | ved-move-biblehub-interlinear-block-up | ved-move-biblehub-interlinear-block-up | ved-move-biblehub-interlinear-block-up")))

(defn test-biblehub-interlinear-join-blocks
  []
  ;; (myshell/tv (biblehub-interlinear-join-blocks "1473    \n-----   \n------  \nof us   \nPPro-G1P" "1|73    \n-----   \n------  \no| us   \nP|ro-G1P"))
  ;; (myshell/tv (biblehub-interlinear-join-blocks (s/trim-newline (slurp "/root/dump/tmp/scratchu8qQfJ.txt")) "1|73    \n-----   \n------  \no| us   \nP|ro-G1P"))
  ;; (myshell/tv (biblehub-interlinear-join-blocks (slurp "/root/dump/tmp/scratchu8qQfJ.txt") "1|73    \n-----   \n------  \no| us   \nP|ro-G1P"))
  (myshell/tv (biblehub-interlinear-join-blocks (myshell/sn "ocif curl \"https://biblehub.com/interlinear/genesis/1-1.htm\" | biblehub-interlinear-get-word-blocks-pipeline | sed '${/^$/d}' | awk 1") "1|73    \n-----   \n------  \no| us   \nP|ro-G1P")))


(defn transform-line [line]
  (let [modified-line (s/replace line #"(\w+)\(\"(\d+)\", \"(.+)\"\),"
                                 "| $1 | $2 | $3 |")]
    modified-line))

;; Cider REPL doesn't hang because this uses a -main function
(defn -main [& args]
  (let [blockstext (slurp (clojure.java.io/reader *in*))
        blocksperline (myshell/snc "biblehub-interlinear-word-blocks-per-line" blockstext)
        splittext (s/split blockstext #"\n\n")

        alljoined (reduce 'biblehub-interlinear-join-blocks
                          splittext)]

  
    ;; (myshell/tv blocksperline)
    ;; (myshell/tv (first splittext))
    (myshell/tv alljoined)))

