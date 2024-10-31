#!/usr/bin/env bb

(ns utils.left-pad
  (:require [babashka.deps :as deps]))

(require '[babashka.deps :as deps])
(deps/add-deps '{:deps {coldnew/left-pad {:mvn/version "1.0.0"}}})

(require '[coldnew.left-pad :refer [leftpad]])
(print (leftpad "Hello, world!" 20 "-"))
