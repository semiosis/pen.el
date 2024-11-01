#!/usr/bin/env bbb

;; bb /volumes/home/shane/var/smulliga/source/git/babashka/babashka/examples/which.clj gedit

(ns utils.which
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]))

;; It's also probably possible to include clojure.contrib.def in babashka with deps
;; Contrib is deprecated though
;; (use 'clojure.contrib.def)
;; (deps/add-deps '{:deps {org.clojure/contrib.def {:mvn/version "0.2.0"}}})
;; (require '[clojure.contrib.def :as d])

(require '[clojure.java.io :as io])

(defn which [executable]
  (let [path (System/getenv "PATH")
        paths (.split path (System/getProperty "path.separator"))]
    (loop [paths paths]
      (when-first [p paths]
        (let [f (io/file p executable)]
          (if (and (.isFile f)
                   (.canExecute f))
            (.getCanonicalPath f)
            (recur (rest paths))))))))


;; Contrib is deprecated though
;; A synonym for a macro must be defined using a macro
;; or with clojure.contrib.def/defalias
;; https://stackoverflow.com/questions/1317396/define-a-synonym-for-a-clojure-macro
;; (def 'foreach 'doseq)
(defmacro foreach [& args] `(doseq ~@args))

;; I can E on -main function now from lispy
;; e.g.
;; (1/3) & args:
;; foo -5
(defn -main [& args]
  (comment
    (myshell/tv (str (count args)
                     "\n" args)))

  ;; bbb handles the -main well now.
  ;; So does lispy E in cider
  (if args
    (do
      (comment
        ;; This works, but I want to use standard clojure
        (foreach [a args]
                 (when-let [executable a]
                   (println (myshell/tv (which executable))))))
      (doseq [a args]
                 (when-let [executable a]
                   (println (myshell/tv (which executable))))))
    (when-let [executable (first *command-line-args*)]
      (println (which executable)))))
