#!/usr/bin/env bb

(ns utils.hiragana-to-romanji
  (:require [babashka.deps :as deps]))

;; e:$EMACSD/pen.el/scripts/org-scripts/hello-world.org
;; cat /volumes/home/shane/var/smulliga/source/git/semiosis/thoughts-on-theology/README.org | org-mode-make-headline-asterisks-into-slash.bb | v

(require '[clojure.string :as s]
         '[clojure.java.io :as io])

(comment
  (let [line "* YO"]
    (if-some [ ;; destructuring form
              [whole-match stars title]
              ;; Match headings
              (re-matches #"^(\*+) (.*)" line)]
      (println "HEAD" stars title) ;; matching case
      (println line))))

(defn transform-line [line]
  (comment
    (let [line "* YO"]
      (def matcher (re-matcher #"^(\*+) (.*)" line))
      (if (re-find matcher)
        (do
          (println "YO")
          (s/replace line "*" "/"))
        line)))

  ;; Works
  (comment
    (let [line "* YO"]
      (if-some [ ;; destructuring form
                [whole-match stars title]
                ;; Match headings
                (re-matches #"^(\*+) (.*)" line)]
        (println "HEAD" stars title) ;; matching case
        (println line))))

  (if-some [ ;; destructuring form
            [whole-match stars title]
            ;; Match headings
            (re-matches #"^(\*+) (.*)" line)]

    (str stars " " (s/replace title "*" "/"))
    (str line)))

(doseq [line (line-seq (clojure.java.io/reader *in*))]
  (println (transform-line line)))
