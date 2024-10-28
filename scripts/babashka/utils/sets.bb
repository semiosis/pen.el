#!/usr/bin/env bbb

(ns utils.sets)

(class #{1 2 3}) ; => clojure.lang.PersistentHashSet
(set [1 2 3 1 2 3 3 2 1 3 2 1]) ; => #{1 2 3}

; Add a member with conj
(conj #{1 2 3} 4) ; => #{1 2 3 4}

; Remove one with disj
(disj #{1 2 3} 1) ; => #{2 3}

; Test for existence by using the set as a function:
(#{1 2 3} 1) ; => 1
(#{1 2 3} 4) ; => nil

; There are more functions in the clojure.sets namespace.
