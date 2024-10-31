#!/usr/bin/env bbb

(ns utils.monads
  (:require [babashka.deps :as deps])
  ;; (:require [ as m])
  )

(deps/add-deps '{:deps {org.clojure/algo.monads {:mvn/version "0.2.0"}}})

(require '[clojure.algo.monads :as m])

(let [a  1
      b  (inc a)]
  (* a b))

;; The functional equivalent of the let form.
;; - The computational steps appear in reverse order
((fn [a]
   ((fn [b]
      (* a b))
    (inc a)))
 1)

;; We can put the steps in the right order with a small helper function, bind
(defn m-bind [value function]
  (function value))
(m-bind 1        (fn [a]
(m-bind (inc a)  (fn [b]
        (* a b)))))

(println
 (m/domonad m/identity-m
            [a  1
             b  (inc a)]
            (* a b)))
