#!/usr/bin/env bbb

;; bb /volumes/home/shane/var/smulliga/source/git/babashka/babashka/examples/which.clj gedit

(ns utils.which
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]))

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

(defn -main [& args]
  (myshell/tv (str (count args)
                   "\n" args))
  (when-let [executable (first *command-line-args*)]
    (println (which executable))))
