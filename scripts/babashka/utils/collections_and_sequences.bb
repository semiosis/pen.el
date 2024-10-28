#!/usr/bin/env bbb

(ns utils.collections-and-sequences)

                                        ; Lists are linked-list data structures, while Vectors are array-backed.
                                        ; Vectors and Lists are java classes too!
(class [1 2 3])                         ; => clojure.lang.PersistentVector
(class '(1 2 3)); => clojure.lang.PersistentList

; A list would be written as just (1 2 3), but we have to quote
; it to stop the reader thinking it's a function.
; Also, (list 1 2 3) is the same as '(1 2 3)

; "Collections" are just groups of data
; Both lists and vectors are collections:
(coll? '(1 2 3)) ; => true
(coll? [1 2 3]) ; => true

; "Sequences" (seqs) are abstract descriptions of lists of data.
; Only lists are seqs.
(seq? '(1 2 3)) ; => true
(seq? [1 2 3]) ; => false

; A seq need only provide an entry when it is accessed.
; So, seqs which can be lazy -- they can define infinite series:
(range 4) ; => (0 1 2 3)
(comment (range)) ; => (0 1 2 3 4 ...) (an infinite series)
(take 4 (range)) ;  (0 1 2 3)

; Use cons to add an item to the beginning of a list or vector
(cons 4 [1 2 3]) ; => (4 1 2 3)
(cons 4 '(1 2 3)) ; => (4 1 2 3)

; Conj will add an item to a collection in the most efficient way.
; For lists, they insert at the beginning. For vectors, they insert at the end.
(conj [1 2 3] 4) ; => [1 2 3 4]
(conj '(1 2 3) 4) ; => (4 1 2 3)

; Use concat to add lists or vectors together
(concat [1 2] '(3 4)) ; => (1 2 3 4)

; Use filter, map to interact with collections
(map inc [1 2 3]) ; => (2 3 4)
(filter even? [1 2 3]) ; => (2)

; Use reduce to reduce them
(reduce + [1 2 3 4])
; = (+ (+ (+ 1 2) 3) 4)
; => 10

; Reduce can take an initial-value argument too
(reduce conj [] '(3 2 1))
; = (conj (conj (conj [] 3) 2) 1)
; => [3 2 1]
