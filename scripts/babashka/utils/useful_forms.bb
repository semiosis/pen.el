#!/usr/bin/env bbb

(ns utils.useful-forms)

; Logic constructs in clojure are just macros, and look like
; everything else
(if false "a" "b") ; => "b"
(if false "a") ; => nil

; Use let to create temporary bindings
(let [a 1 b 2]
  (> a b)) ; => false

; Group statements together with do
(do
  (print "Hello")
  "World") ; => "World" (prints "Hello")

; Functions have an implicit do
(defn print-and-say-hello [name]
  (print "Saying hello to " name)
  (str "Hello " name))
(print-and-say-hello "Jeff") ;=> "Hello Jeff" (prints "Saying hello to Jeff")

; So does let
(let [name "Urkel"]
  (print "Saying hello to " name)
  (str "Hello " name)) ; => "Hello Urkel" (prints "Saying hello to Urkel")


; Use the threading macros (-> and ->>) to express transformations of
; data more clearly.

; The "Thread-first" macro (->) inserts into each form the result of
; the previous, as the first argument (second item)
(->  
   {:a 1 :b 2} 
   (assoc :c 3) ;=> (assoc {:a 1 :b 2} :c 3)
   (dissoc :b)) ;=> (dissoc (assoc {:a 1 :b 2} :c 3) :b)

; This expression could be written as:
; (dissoc (assoc {:a 1 :b 2} :c 3) :b)
; and evaluates to {:a 1 :c 3}

; The double arrow does the same thing, but inserts the result of
; each line at the *end* of the form. This is useful for collection
; operations in particular:
(->>
   (range 10)
   (map inc)     ;=> (map inc (range 10)
   (filter odd?) ;=> (filter odd? (map inc (range 10))
   (into []))    ;=> (into [] (filter odd? (map inc (range 10)))
                 ; Result: [1 3 5 7 9]

; When you are in a situation where you want more freedom as where to
; put the result of previous data transformations in an 
; expression, you can use the as-> macro. With it, you can assign a
; specific name to transformations' output and use it as a
; placeholder in your chained expressions:

(as-> [1 2 3] input
  (map inc input);=> You can use last transform's output at the last position
  (nth input 2) ;=>  and at the second position, in the same expression
  (conj [4 5 6] input [8 9 10])) ;=> or in the middle !
