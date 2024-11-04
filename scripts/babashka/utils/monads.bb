#!/usr/bin/env bbb

(ns utils.monads
  (:require [babashka.deps :as deps]
            [utils.myshell :as myshell]
            [utils.misc :as ms]))

;; [utils.myshell :as myshell]

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

;; I should make a monad out of this
(defn println-and-return
  ""
  [o]
  (println o)
  o)

(ms/println-and-return
 (m/domonad m/identity-m
            [a  1
             b  (inc a)]
            (* a b)))

;; Maybe monad
(defn f [x]
  (m/domonad m/maybe-m
    [a  x
     b  (inc a)]
    (* a b)))

(ms/println-and-return (f 5))

(comment
  ;; the maybe monad's bind function looks a bit like this
  (defn m-bind [value function]
    (if (nil? value)
      nil
      ;; `value` represents the rest of the computation
      (function value))))

;; println monad - my own monad - yay I made a monad! - in clojure!
(m/defmonad println-m
  "Monad describing plain computations. This monad does in fact nothing
    at all. It is useful for testing, for combination with monad
    transformers, and for code that is parameterized with a monad."
  [m-result identity
   m-bind   (fn m-result-id [mv f]
              (ms/println-and-return
               (f mv)))])
(m/domonad println-m
           [a  1
            b  (inc a)]
           (* a b))

;; sequence monad (known in the Haskell world as the list monad.
;; In Clojure, a for form is a sequence monad
(for [a (range 5)
      b (range a)]
  (* a b))

;; We already know that the domonad macro expands into a chain of `m-bind` calls,
;; ending in an expression that calls `m-result`.
;; `m/sequence-m` seems to run a permutation of computations.
(comment
  (m/domonad m/sequence-m
             [a (range 5)
              ;; This doesn't work like (myshell/tv [0 2 3 4 5])
              ;; b (range (myshell/tv a))
              ;; It runs myshell/tv once for every element
              b (range a)]
             (* a b)))
