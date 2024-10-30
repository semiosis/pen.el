#!/usr/bin/env bb

(ns utils.is-tty
  (:require [babashka.process :as p])
  (:require [utils.common :as uc])
  )

(defn- is-tty
  [fd key]
  (-> ["test" "-t" (str fd)]
      (p/process {key :inherit :env {}})
      deref
      :exit
      (= 0)))

(defn in-is-tty? [] (is-tty 0 :in))
(defn out-is-tty? [] (is-tty 1 :out))
(defn err-is-tty? [] (is-tty 2 :err))

(when (uc/invoked-as-script-p)
  (println "STDIN is TTY?:" (in-is-tty?))
  (println "STDOUT is TTY?:" (out-is-tty?))
  (println "STDERR is TTY?:" (err-is-tty?)))
