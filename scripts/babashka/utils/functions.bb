#!/usr/bin/env bbb

(ns utils.functions)

; Use fn to create new functions. A function always returns
; its last statement.
(fn [] "Hello World") ; => fn

; (You need extra parens to call it)
((fn [] "Hello World")) ; => "Hello World"

; You can create a var using def
(def x 1)
(println x) ; => 1

; Assign a function to a var
(def hello-world (fn [] "Hello World"))
(println (hello-world)) ; => "Hello World"

; You can shorten this process by using defn
(defn hello-world [] "Hello World")

; The [] is the list of arguments for the function.
(defn hello [name]
  (str "Hello " name))
(println (hello "Steve")) ; => "Hello Steve"

; Private function
(defn- re-group-start
  "Return the starting delimiter of a regular expression group."
  [capture?]
  (if capture? "(" "(?:"))

; You can also use this shorthand to create functions:
(def hello2 #(str "Hello " %1))
(println (hello2 "Julie")) ; => "Hello Julie"

; You can have multi-variadic functions, too
(defn hello3
  ([] "Hello World")
  ([name] (str "Hello " name)))
(println (hello3 "Jake")) ; => "Hello Jake"
(println (hello3)) ; => "Hello World"

; Functions can pack extra arguments up in a seq for you
(defn count-args [& args]
  (str "You passed " (count args) " args: " args))
(println (count-args 1 2 3)) ; => "You passed 3 args: (1 2 3)"

; You can mix regular and packed arguments
(defn hello-count [name & args]
  (str "Hello " name ", you passed " (count args) " extra args"))
(println (hello-count "Finn" 1 2 3))
; => "Hello Finn, you passed 3 extra args"
