#!/usr/bin/env bbb

(ns utils.stm)

; Software Transactional Memory is the mechanism clojure uses to handle
; persistent state. There are a few constructs in clojure that use this.

; An atom is the simplest. Pass it an initial value
(def my-atom (atom {}))

; Update an atom with swap!.
; swap! takes a function and calls it with the current value of the atom
; as the first argument, and any trailing arguments as the second
(swap! my-atom assoc :a 1) ; Sets my-atom to the result of (assoc {} :a 1)
(swap! my-atom assoc :b 2) ; Sets my-atom to the result of (assoc {:a 1} :b 2)

; Use '@' to dereference the atom and get the value
my-atom  ;=> Atom<#...> (Returns the Atom object)
@my-atom ; => {:a 1 :b 2}

; Here's a simple counter using an atom
(def counter (atom 0))
(defn inc-counter []
  (swap! counter inc))

(inc-counter)
(inc-counter)
(inc-counter)
(inc-counter)
(inc-counter)

@counter ; => 5

; Other STM constructs are refs and agents.
; Refs: http://clojure.org/refs
; Agents: http://clojure.org/agents
