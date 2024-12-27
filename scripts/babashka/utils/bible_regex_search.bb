#!/usr/bin/env bbb

;; cd "$PENCONF/documents/notes"; bible_regex_search.bb BSB "blessed.*is"

(ns utils.bible-regex-search
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]
            [utils.aliases :as aliases]))

(require '[clojure.java.io :as io])

;; I can E on -main function now from lispy
;; e.g.
;; (1/3) & args:
;; foo -5
(defn -main [& args]

  (let [bible-translation (first args)
        regex (second args)]
    ;; https://clojuredocs.org/clojure.core/format
    (println
     (myshell/snc
      (myshell/cmd
       "sqlite3"
       (format
        "/root/repos/aaronjohnsabu1999/bible-databases/DB/%sBible_Database.db"
        bible-translation)
       (format
        "select Book, Chapter, Versecount, verse from bible where verse IS NOT NULL AND verse REGEXP %s limit 10"
        (myshell/cmd regex))
       ".exit")))))
