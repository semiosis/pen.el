#!/usr/bin/env bb

;; https://github.com/babashka/process

;; (ns enter-your-name)
(ns utils.myshell
  (:require [babashka.deps :as deps]
            [clojure.string :as str])
  (:import
   (java.io File)
   (java.nio.file Paths)))

(require '[babashka.process :refer [shell process exec]])

(use '[clojure.java.shell :only [sh]])
(use '[clojure.string :only (join split upper-case)])

(comment
  (load-file "src/mylib/core.clj"))

;; TODO Make a cmd function in babashka
;; e:$EMACSD/khala/src/khala/utils.clj

;; I need un 'uncmd'
(defn cmd
  ""
  [& args]
  ;; clojure.string/join
  (join
   " "
   ;; I have to use the jq version so unicode works
   ;; But it's much slower. So I have to rewrite this with clojure
   (map (fn [s] (->
                 (sh "pen-q-jq" :in (str s))
                 :out)) args)))

(comment
  (uncmd "yo \"wassup noob\" yo"))

(defn uncmd
  "Example:
(uncmd \"yo \\\"wassup noob\\\" yo\")

emacs' s-lines is replaced by split.
  "
  [s]
  (split
   (:out (sh "bash" "-c" (str "pl " s)))
   #"\n"))

(defn tv [s]
  (sh "pen-tv" :in (str s))
  s)

(defn tpvipe [s]
  (:out (sh "tpvipe" :in (str s))))
;; TODO Figure out how to make s optional - then I can use this to insert stuff into babashka

;; she and snc1 effectively do the same thing, but not really
(defn she [s]
  (:out
   (sh "sh" "-c" s :in (str s))))

(defn snc [s]
  (:out
   (sh "sh" "-c" s :in (str s))))

(defn snc1
  ""
  [s]
  ;; Ah, the problem with this is that it's unable to include pipes
  (:out (eval `(sh ~@(uncmd (str s))))))

(defn tm-notify [s]
  (sh "tm-notify" :in (str s))
  s)

(defn tvipe [s]
  (:out
   (sh "pen-tvipe" :in s)))

(defn args-to-envs [args]
  (join "\n"
        (map (fn [[key value]]
               (str
                (str/replace
                 (upper-case
                  (name key))
                 "-" "_")
                "=" (cmd value)))
             (seq args))))


(defn string-to-uri [s]
  (-> s File. .toURI))

(defn uri-to-path [s]
  (Paths/get s))

(defn string-to-path [s]
  (-> s string-to-uri uri-to-path))

(defn split-by-slash [s]
  (clojure.string/split s #"/"))

(defn member [s col]
  (some #(= s %) col))

(defn expand-home [s]
  (as-> s binding
    (clojure.string/replace-first binding "$HOME" (System/getProperty "user.home"))
    (clojure.string/replace-first binding "$HOME" (System/getProperty "user.home"))))

(defn get-filename-only [s]
  (nth (reverse (split-by-slash s)) 0))

(comment
  (println (:out (shell "ls" "-la")))
  (println (:out (sh "ls" "-la")))) ;; no options

(comment
  (shell "ls -la" ".")) ;; first string is tokenized automatically, more strings may be provided

(comment
  (tv (:out (eval `(sh ~@(uncmd "ls -la ."))))))

(comment
  (shell {:dir "."} "ls" "-la")
  (process {:in "hello"} "cat")

  (let [progs '["v" "nano"]]
    (doseq [i progs]
      (println (str "Babashka starting " i "..."))
    ;; (shell {:extra-env {"FOO" "BAR"}} (str "sps " i))
      (shell i)))

  (doseq [i '["v" "nano"]]
    (println i))

  ;; Start the REPL
  (clojure.main/repl)

  (tv "yo")

  ;; TODO Figure out how to start the babashka repl from inside the script

  ;; exec seems to terminate the babashka script when it runs the program
  (exec {:extra-env {"FOO" "BAR"}} "bash -c 'echo $FOO' | sps v")

  (comment
    ;; 
    (for [i '[1 2]]
      (println (str "Babashka starting " i "...")))

    ;; Why does this not work? I think it's because a Clojure for may not be able to take a list of strings
    (for [i '["nano" "vim"]]
      (println (str "Babashka starting " i "..."))
      (exec {:extra-env {"FOO" "BAR"}} i))))
