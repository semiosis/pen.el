#!/usr/bin/env bbb

(ns utils.modules)

; Use "use" to get all functions from the module
(use 'clojure.set)

; Now we can use set operations
(intersection #{1 2 3} #{2 3 4}) ; => #{2 3}
(difference #{1 2 3} #{2 3 4}) ; => #{1}

; You can choose a subset of functions to import, too
(use '[clojure.set :only [intersection]])

; Use require to import a module
(require 'clojure.string)

; Use / to call functions from a module
; Here, the module is clojure.string and the function is blank?
(clojure.string/blank? "") ; => true

; You can give a module a shorter name on import
(require '[clojure.string :as str])
(str/replace "This is a test." #"[a-o]" str/upper-case) ; => "THIs Is A tEst."
; (#"" denotes a regular expression literal)

; You can use require (and use, but don't) from a namespace using :require.
; You don't need to quote your modules if you do it this way.
(comment
  (ns test
    (:require
     [clojure.string :as str]
     [clojure.set :as set])))
