#!/usr/bin/env -S clojure-shebang

;; https://github.com/clj-commons/seesaw
;; Seesaw is a library/DSL for constructing user interfaces in Clojure. It happens to be built on Swing, but please don't hold that against it.

(ns utils.seesaw
  (:use seesaw.core))

(defn -main [& args]
  (invoke-later
    (-> (frame :title "Hello",
           :content "Hello, Seesaw",
           :on-close :exit)
     pack!
     show!)))
