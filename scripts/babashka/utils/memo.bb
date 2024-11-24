#!/usr/bin/env bbb

(ns utils.memo
  (:require [utils.myshell :as myshell]
            [utils.is-tty :as tty]
            [clojure.string :as s]
            [utils.misc :as ms]))

;; [[sh:echo egg | memo.bb put pot]]
;; [[sps:memo.bb get pot; pak]]
;; [[sh:memo.bb get pot]]

(require '[clojure.java.io :as io])

(defn stash [file-name]
  (with-open [os (java.util.zip.GZIPOutputStream. (io/output-stream (str "/tmp/" file-name ".zip")))]
    (.write os (.getBytes (slurp *in*)))
    (.finish os))
  'ok)

(defn unstash [file-name]
  (slurp (java.util.zip.GZIPInputStream. (io/input-stream (str "/tmp/" file-name ".zip")))))

(defn print-or-tv
  ""
  [s]
  (if (tty/out-is-tty?)
    (ms/println-and-return (s/trim-newline s))
    (myshell/tv s)))

(def sym2str name)

(defn -main [& args]
  (let [[action stash-name]
        (or args
            *command-line-args*)]
    (print-or-tv
     (case action
       "put" (name (stash stash-name))
       "get" (unstash stash-name)
       (str "Invalid op:" action)))))
