#!/usr/bin/env bbb

;; agi sqlite3-pcre
;; cd "$PENCONF/documents/notes"; bible_regex_search.bb BSB "blessed.*is"

(ns utils.bible-regex-search
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]
            [utils.aliases :as aliases]
            [clojure.string :as s]))

(require '[clojure.java.io :as io])

;; I can E on -main function now from lispy
;; e.g.
;; (1/3) & args:
;; foo -5
(defn -main [& args]

  (let [bible-translation (first args)
        regex (second args)]
    ;; https://clojuredocs.org/clojure.core/format
    (print
     (myshell/snc
      (myshell/cmd
       "sqlite3"
       (format
        "/root/repos/aaronjohnsabu1999/bible-databases/DB/%sBible_Database.db"
        bible-translation)
       (format
        "select Book, Chapter, Versecount, verse from bible where verse IS NOT NULL AND lower(verse) REGEXP %s limit 100"
        (myshell/cmd (s/lower-case regex)))
       ".exit")))))
